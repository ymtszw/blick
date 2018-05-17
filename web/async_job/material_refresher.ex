use Croma

defmodule Blick.AsyncJob.MaterialRefresher do
  alias Croma.Result, as: R
  alias Antikythera.{Time, Cron}
  alias AntikytheraAcs.Dodai.Repo.Datastore
  alias Blick.External.Google
  alias Blick.External.Google.Drive.Files
  alias Blick.Repo
  alias Blick.Model.Material
  use Antikythera.AsyncJob

  @type refresh_option_t :: {:force, boolean}

  @impl true
  def run(_payload, _metadata, _context) do
    refresh()
  end

  @gear_pool {:gear, :blick}
  @id "MaterialRefresher"

  def run_hourly() do
    {Time, _ymd, {_h, m, _s}, _ms} = Time.now() |> Time.shift_minutes(1) # Let first one start after a minute
    register(%{}, @gear_pool, id: @id, schedule: {:cron, Cron.parse!("#{m} * * * *")})
  end

  def status() do
    Antikythera.AsyncJob.status(@gear_pool, @id)
  end

  @doc """
  Refresh Materials, mainly thumbnails and excluded status.

  Google Drive Files' thumbnail URL links expire in order of hours.
  So this function should be called periodically.

  If `force: true`, refreshes all existing thumbnails, not just Google Drive Files.
  Defaults to `false`.
  """
  defun refresh() :: R.t([Material.t]) do
    R.m do
      materials <- Repo.Material.dict_all()
      token <- Repo.AdminToken.retrieve()
      id_and_update_actions <- materials |> Map.values() |> refresh_impl(token)
      Repo.Material.update_all(id_and_update_actions)
    end
  end

  defp refresh_impl(materials, token) do
    {google_materials, other_materials} =
      Enum.split_with(materials, fn %Material{data: %Material.Data{type: type}} ->
        type in [:google_doc, :google_slide, :google_file]
      end)
    R.m do
      google_updates <- google_materials |> filter_excluded() |> refresh_google_material_thumbnails(token)
      other_updates <- other_materials |> filter_excluded() |> refresh_other_materials()
      pure google_updates ++ other_updates
    end
  end

  defp filter_excluded(materials) do
    Enum.reject(materials, &(&1.data.excluded))
  end

  defunp refresh_google_material_thumbnails(google_materials :: v[[Material.t]], token :: Google.token_t) :: R.t([{Material.Id.t, Datastore.update_action_t}]) do
    batch_get_details(google_materials, token)
    |> R.bind(fn
      get_detail_results when length(get_detail_results) == length(google_materials) ->
        google_materials
        |> Enum.sort_by(&Material.google_file_id!/1)
        |> Enum.zip(get_detail_results)
        |> Enum.map(&make_update_action/1)
        |> Enum.reject(&is_nil/1)
        |> R.pure()
    end)
  end

  defp batch_get_details(google_materials, token) do
    google_materials
    |> Enum.map(&Material.google_file_id!/1)
    |> Files.batch_get(token) # Results will be sorted by file_id
  end

  defunp refresh_other_materials(other_materials :: v[[Material.t]]) :: R.t([{Material.Id.t, Datastore.update_action_t}]) do
    other_materials
    |> Enum.map(&renormalize_other_material/1)
    |> Enum.reject(&is_nil/1)
    |> R.pure()
  end

  defp renormalize_other_material(%Material{_id: id, data: %Material.Data{type: type0, url: url0}}) do
    case Material.normalize_url_by_types(url0) do
      {^type0, ^url0} ->
        nil # No change
      {type1, url1} ->
        set_type = if type1 == type0, do: %{}, else: %{type: type1}
        set_url = if url1 == url0, do: %{}, else: %{type: url1}
        {id, %{data: %{"$set" => Map.merge(set_type, set_url)}}}
    end
  end

  # Also used from Material controller
  @spec make_update_action({Material.t, Google.multipart_res_t}) :: nil | {Material.Id.t, Datastore.update_action_t}
  def make_update_action({%Material{_id: id}, {404, _resp_body}}) do
    {id, %{data: %{"$set" => %{excluded: true, exclude_reason: "Not found on Google Drive."}}}}
  end
  def make_update_action({material, {403, %{"error" => %{"errors" => [%{"domain" => "usageLimits"} | _]}}}}) do
    Blick.Logger.debug("Rate Limit on: #{inspect(material)}")
    nil # Skip on rate limit; if not inserted, it should be retried on next job attempt.
  end
  def make_update_action({%Material{_id: id}, {200, file}}) do
    thumbnail_url = Blick.AsyncJob.MaterialCollector.enlarge_thumbnail_size(file["thumbnailLink"])
    {id, %{data: %{"$set" => %{thumbnail_url: thumbnail_url}}}}
  end
end
