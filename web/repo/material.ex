use Croma

defmodule Blick.Repo.Material do
  alias Croma.Result, as: R
  import Blick.Dodai, only: [root_key: 0]
  alias Blick.Model.Material
  use SolomonAcs.Dodai.Repo.Datastore, [
    datastore_models: [Material],
    read_permission: :anyone,
    write_permission: :anyone,
  ]

  @doc """
  Insert requested id/data pair list recursively.

  Should only be used from material collecter jobs in order to populate Material Repo,
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
  Retrieves ALL existing materials in `_id`-keyed map.

  This API will be used by periodically-running material collecter jobs,
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
end
