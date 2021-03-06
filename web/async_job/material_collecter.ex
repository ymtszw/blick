use Croma

defmodule Blick.AsyncJob.MaterialCollector do
  alias Croma.Result, as: R
  alias Blick.External.Google
  alias Blick.External.Google.{Spreadsheets, Drive.Files}
  alias Blick.Repo
  alias Blick.Model.Material
  use Antikythera.AsyncJob

  @impl true
  def run(_payload, _metadata, _context) do
    collect_new_materials_from_rnd_seminar_spreadsheet()
  end

  @rnd_seminar_spreadsheet_id "1j-ag_0n1CyLAjOTNA5bVYuCN4uq-UbFKYavU4dvh1G8"

  @doc """
  Collect new materials from (now-defunct) RnD seminar schedule spreadsheet.

  Results are inserted to Material Repo.

  It deduplicates already existing materials by looking up current Material Repo,
  so it should produce smaller size of result compared to number of all URLs found in the spreadsheet.
  """
  defun collect_new_materials_from_rnd_seminar_spreadsheet() :: R.t([Material.t]) do
    R.m do
      current_material_dict <- Repo.Material.dict_all()
      token <- Repo.AdminToken.retrieve()
      file <- Spreadsheets.get(@rnd_seminar_spreadsheet_id, token) # This can take a few seconds
      schedule_sheets <- get_shedule_sheets(file["sheets"] || [])
      new_material_with_ids <-
        schedule_sheets
        |> parse_schedule_sheets()
        |> take_sample()
        |> deduplicate(current_material_dict)
        |> normalize_with_additional_lookups(token)
      Repo.Material.insert_all(new_material_with_ids)
    end
  end

  defp get_shedule_sheets(sheets) do
    case Enum.reverse(sheets) do
      [_dice_roll_sheet | schedule_sheets] -> {:ok, schedule_sheets}
      _ -> {:error, :unexpected_sheet_format}
    end
  end

  defp parse_schedule_sheets(schedule_sheets) do
    schedule_sheets |> Enum.flat_map(&parse_sheet/1) |> uniq_materials()
  end

  defp parse_sheet(%{"data" => grid_data_list}) do
    Enum.flat_map(grid_data_list, &parse_grid_data/1)
  end

  defp parse_grid_data(%{"rowData" => row_data_list}) do
    Enum.flat_map(row_data_list, &parse_row_data/1)
  end

  @excluded_patterns [
    "0B6DpgpRl_A1mfl9VblV6Rlk0TTM2YmlmYVYtUDE0VWo3ZmZ0b3BMSk55clRnYXMwN3h4N2c", # RnD seminar material directory ID
  ]

  defunp parse_row_data(%{"values" => cell_data_list} :: map) :: [Material.Data.t] do
    Enum.reduce(cell_data_list, [], fn cell, acc ->
      case cell["hyperlink"] do
        "http" <> _ = url ->
          if not Enum.any?(@excluded_patterns, &String.contains?(url, &1)) do
            {type, normalized_url} = Material.normalize_url_by_types(url)
            [%Material.Data{type: type, url: normalized_url, title: cell["formattedValue"] || normalized_url} | acc]
          else
            acc
          end
        _ ->
          acc
      end
    end)
  end

  defp uniq_materials(materials) do
    materials
    |> Enum.uniq_by(fn %Material.Data{url: normalized_url} -> normalized_url end)
    |> Enum.uniq_by(fn %Material.Data{title: title} -> title end)
  end

  if Antikythera.Env.compiling_for_cloud?() do
    defp take_sample(materials), do: materials
  else
    defp take_sample(materials), do: materials |> Enum.shuffle() |> Enum.take(20) # Should better be kept in order to avoid hitting rate limit
  end

  defunp deduplicate(materials :: v[[Material.Data.t]], current_material_dict :: %{Material.Id.t => Material.t}) :: [{Material.Id.t, Material.Data.t}] do
    Enum.reduce(materials, [], fn %Material.Data{url: normalized_url} = material_data, acc ->
      id = Material.generate_id(normalized_url)
      if Map.has_key?(current_material_dict, id) do
        acc
      else
        [{id, material_data} | acc]
      end
    end)
  end

  defp normalize_with_additional_lookups(id_and_materials, token) do
    {google_materials, other_materials} =
      Enum.split_with(id_and_materials, fn {_id, %Material.Data{type: type}} -> type in [:google_doc, :google_slide, :google_file] end)
    google_materials
    |> renormalize_and_add_details_to_google_materials(token)
    |> R.map(&(other_materials ++ &1))
  end

  defunp renormalize_and_add_details_to_google_materials(id_and_google_materials :: [{Material.Id.t, Material.Data.t}], token :: Google.token_t) :: R.t([{Material.Id.t, Material.Data.t}]) do
    batch_get_details(id_and_google_materials, token)
    |> R.bind(fn
      get_detail_results when length(get_detail_results) == length(id_and_google_materials) ->
        id_and_google_materials
        |> Enum.sort_by(&(Material.google_file_id!(elem(&1, 1))))
        |> Enum.zip(get_detail_results)
        |> Enum.map(&renormalize_and_add_details_impl/1)
        |> Enum.reject(&is_nil/1)
        |> R.pure()
      results ->
        Blick.Logger.error("Insufficient Google.Drive.Files.batch_get/2 results. Got: #{inspect(results)}")
        {:error, :batch_get_files_missing_some_response}
    end)
  end

  defp batch_get_details(id_and_google_materials, token) do
    id_and_google_materials
    |> Enum.map(&(Material.google_file_id!(elem(&1, 1))))
    |> Files.batch_get(token) # Result will be sorted by file_id
  end

  @spec renormalize_and_add_details_impl({{Material.Id.t, Material.Data.t}, Google.multipart_res_t}) :: nil | {Material.Id.t, Material.Data.t}
  defp renormalize_and_add_details_impl({{id, %Material.Data{} = deleted_material}, {404, _resp_body}}) do
    {id, %Material.Data{deleted_material | excluded: true, exclude_reason: "Not found on Google Drive."}}
  end
  defp renormalize_and_add_details_impl({id_and_material, {403, %{"error" => %{"errors" => [%{"domain" => "usageLimits"} | _]}}}}) do
    Blick.Logger.debug("Rate Limit on: #{inspect(id_and_material)}")
    nil # Skip on rate limit; if not inserted, it should be retried on next job attempt.
  end
  defp renormalize_and_add_details_impl({{id, %Material.Data{type: :google_slide} = found_material}, {200, file}}) do
    {_file_id, "application/vnd.google-apps.presentation", thumbnail_url, author_email, created_time} = details(file)
    {id, %Material.Data{found_material | author_email: author_email, thumbnail_url: thumbnail_url, created_time: created_time}}
  end
  defp renormalize_and_add_details_impl({{id, %Material.Data{type: :google_doc} = found_material}, {200, file}}) do
    {_file_id, "application/vnd.google-apps.document", thumbnail_url, author_email, created_time} = details(file)
    {id, %Material.Data{found_material | author_email: author_email, thumbnail_url: thumbnail_url, created_time: created_time}}
  end
  defp renormalize_and_add_details_impl({{id, %Material.Data{type: :google_file} = found_material}, {200, file}}) do
    {file_id, mimetype, thumbnail_url, author_email, created_time} = details(file)
    case mimetype do
      "application/vnd.google-apps.presentation" ->
        {id, %Material.Data{found_material | type: :google_slide, url: "https://docs.google.com/presentation/d/#{file_id}", author_email: author_email, thumbnail_url: thumbnail_url, created_time: created_time}}
      "application/vnd.google-apps.document" ->
        {id, %Material.Data{found_material | type: :google_doc, url: "https://docs.google.com/document/d/#{file_id}", author_email: author_email, thumbnail_url: thumbnail_url, created_time: created_time}}
      _misc_mimetypes ->
        {id, %Material.Data{found_material | url: "https://drive.google.com/file/d/#{file_id}", author_email: author_email, thumbnail_url: thumbnail_url, created_time: created_time}}
    end
  end

  defp details(%{"id" => file_id,
                 "mimeType" => mimetype,
                 "createdTime" => created_time,
                 "owners" => [%{"emailAddress" => author_email} | _]} = file) do
    {file_id, mimetype, enlarge_thumbnail_size(file["thumbnailLink"]), author_email, Antikythera.Time.from_iso_timestamp(created_time) |> R.get!()}
  end

  # Also used in refresher
  def enlarge_thumbnail_size(nil), do: nil
  def enlarge_thumbnail_size(url) when is_binary(url), do: String.replace(url, "=s220", "=s640") # Yes, it's cheesy
end
