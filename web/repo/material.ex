use Croma

defmodule Blick.Repo.Material do
  alias Croma.Result, as: R
  alias SolomonLib.Time
  alias SolomonAcs.Dodai.Repo.Datastore
  import Blick.Dodai, only: [root_key: 0]
  alias Blick.External.Google.Drive.Files
  alias Blick.Repo
  alias Blick.Model.Material
  alias Blick.AsyncJob.{MaterialRefresher, AsyncRepo}
  use Datastore, [
    datastore_models: [Material],
    read_permission: :anyone,
    write_permission: :anyone,
  ]

  @doc """
  Insert requested id/data pair list recursively.

  Should only be used from material collector jobs in order to populate Material Repo,
  since it can take relatively long time.
  """
  defun insert_all(material_id_and_data_list :: [{Material.Id.t, Material.Data.t}]) :: R.t([Material.t]) do
    root_key = root_key()
    Blick.with_logging_elapsed("Inserted #{length(material_id_and_data_list)} Materials in:", fn ->
      material_id_and_data_list
      |> Enum.map(fn {id, %Material.Data{} = data} -> insert(%{_id: id, data: data}, root_key) end)
      |> R.sequence()
    end)
  end

  @doc """
  Apply all update_actions recursively.

  Should only be used from ThumbnailRefresher job.
  """
  defun update_all(id_and_update_actions :: [{Material.Id.t, Datastore.update_action_t}]) :: R.t([Material.t]) do
    root_key = root_key()
    Blick.with_logging_elapsed("Updated #{length(id_and_update_actions)} Materials in:", fn ->
      id_and_update_actions
      |> Enum.map(fn {id, update_action} -> update(update_action, id, root_key) end)
      |> R.sequence()
    end)
  end

  @doc """
  Retrieves ALL existing materials in `_id`-keyed map.

  This API will be used by periodically-running material collector jobs,
  and used as a lookup table for deduplication.

  If number of materials exceeds 1000, it continuously scanning through chunks of (up to) 1000 entities,
  until (it believes that) all materials are included, and mereges all results.
  It should be practically fast enough since number of seminar/handson materials will be at most 10^4 order,
  which is quite minuscule for MongoDB.

  Since information stored in Material collection are mere metadata,
  it should not become exceedingly large in byte size.
  (Thus should be possible to handle in gear processes.)
  """
  defun dict_all() :: R.t(%{Material.Id.t => Material.t}) do
    Blick.with_logging_elapsed("Fetched all Materials in:", fn -> dict_all_impl(nil, root_key(), %{}) end)
  end

  defp dict_all_impl(lowerbound_id_or_nil, root_key, acc_dict) do
    case retrieve_upto_1000(lowerbound_id_or_nil, root_key) do
      {:ok, []} ->
        {:ok, acc_dict}
      {:ok, [_ | _] = materials} when length(materials) < 1_000 ->
        {:ok, merge_to_dict(materials, acc_dict)}
      {:ok, materials} ->
        last_id = materials |> List.last() |> Material._id()
        dict_all_impl(last_id, root_key, merge_to_dict(materials, acc_dict))
      {:error, _} = e ->
        e
    end
  end

  defp retrieve_upto_1000(nil, root_key) do
    retrieve_list(%{}, root_key)
  end
  defp retrieve_upto_1000(lowerbound_id, root_key) do
    retrieve_list(%{query: %{_id: %{"$gt" => lowerbound_id}}}, root_key)
  end

  defp merge_to_dict(new_materials, acc_dict) do
    new_materials
    |> Map.new(fn %Material{_id: id} = m -> {id, m} end)
    |> Map.merge(acc_dict)
  end

  @on_demand_refresh_threshold_minutes 20
  @not_found Dodai.ResourceNotFound.new()

  @doc """
  Retrieves a Material, and if it is somewhat "old", refresh.

  If the Material is excluded, returns ResourceNotFound.
  """
  defun retrieve_with_refresh(id :: v[Material.Id.t], key :: v[String.t], now :: v[Time.t]) :: R.t(Material.t) do
    threshold = Time.shift_minutes(now, -@on_demand_refresh_threshold_minutes)
    case retrieve(id, key) do
      {:ok, %Material{data: %Material.Data{excluded: true}}} ->
        {:error, @not_found}
      {:ok, %Material{updated_at: updated_at} = material} when updated_at < threshold ->
        {:ok, refresh_and_write_back(material, key)}
      other_result ->
        other_result
    end
  end

  defp refresh_and_write_back(%Material{data: %Material.Data{type: type}} = old_material, key)
  when type in [:google_doc, :google_file, :google_slide] do
    case refresh_google_file_and_write_back(old_material, key) do
      {:ok, new_material} -> new_material
      {:error, _} -> old_material
    end
  end
  defp refresh_and_write_back(other_material, _key) do
    other_material
  end

  defp refresh_google_file_and_write_back(%Material{} = material, key) do
    R.m do
      token <- Repo.AdminToken.retrieve()
      code_and_body <- get_file(Material.google_file_id!(material), token)
      case MaterialRefresher.make_update_action({material, code_and_body}) do
        nil ->
          {:ok, material}
        {id, %{data: %{"$set" => %{thumbnail_url: new_url}}} = ua} ->
          # XXX; This is just an experimental pattern of write back.
          # I think update request to Dodai is fast enough and does not require background task usually.
          AsyncRepo.Material.update(ua, id, key)
          {:ok, put_in(material.data.thumbnail_url, new_url)}
      end
    end
  end

  defp get_file(file_id, token) do
    case Files.get(file_id, token) do
      {:ok, file} ->
        {:ok, {200, file}}
      {:error, %{code: code, body: res_body}} when code in 400..499 ->
        {:ok, {code, Poison.decode!(res_body)}}
      {:error, _} = e ->
        e
    end
  end

  # Queries

  defun only_included(list_action :: Datastore.list_action_t) :: Datastore.list_action_t do
    Blick.MapUtil.deep_merge(list_action, %{query: %{"data.excluded" => false}})
  end

  defun non_google_without_ss() :: Datastore.list_action_t do
    %{
      query: %{
        "data.excluded" => false,
        "data.type" => %{"$in" => ["qiita", "html"]},
        "data.thumbnail_url" => nil,
      },
    }
  end
end
