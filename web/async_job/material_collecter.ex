use Croma

defmodule Blick.AsyncJob.MaterialCollecter do
  alias Croma.Result, as: R
  alias SolomonLib.{Url, Email}
  alias Blick.External.Google
  alias Blick.External.Google.{Spreadsheets, Drive.Files}
  alias Blick.Repo.AdminToken
  alias Blick.Model.Material

  @type material_t :: {Material.Type.t, Url.t, String.t}
    | {Material.Type.t, Url.t, String.t, Email.t, thumbnail_url :: nil | Url.t}

  @rnd_seminar_spreadsheet_id "1j-ag_0n1CyLAjOTNA5bVYuCN4uq-UbFKYavU4dvh1G8"

  @doc """
  Collect materials from (now-defunct) RnD seminar schedule spreadsheet.

  Results are in list of `material_t`.
  """
  defun collect_materials_from_rnd_seminar_spreadsheet() :: R.t([material_t]) do
    R.m do
      token <- AdminToken.retrieve()
      file <- Spreadsheets.get(@rnd_seminar_spreadsheet_id, token) # This can take a few seconds
      schedule_sheets <- get_shedule_sheets(file["sheets"] || [])
      schedule_sheets
      |> parse_schedule_sheets()
      |> take_sample()
      |> normalize_with_additional_lookups(token)
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

  if SolomonLib.Env.compiling_for_cloud?() do
    def take_sample(materials), do: materials
  else
    def take_sample(materials), do: materials |> Enum.shuffle() |> Enum.take(20) # Should better be kept in order to avoid hitting rate limit
  end

  defp uniq_materials(results) do
    results
    |> Enum.uniq_by(fn {_type,  normalized_url, _title} -> normalized_url end)
    |> Enum.uniq_by(fn {_type, _normalized_url,  title} -> title end)
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

  defunp parse_row_data(%{"values" => cell_data_list} :: map) :: material_t do
    Enum.reduce(cell_data_list, [], fn cell, acc ->
      case cell["hyperlink"] do
        "http" <> _ = url ->
          if not Enum.any?(@excluded_patterns, &String.contains?(url, &1)) do
            {type, normalized_url} = Material.normalize_url_by_types(url)
            [{type, normalized_url, cell["formattedValue"] || normalized_url} | acc]
          else
            acc
          end
        _ ->
          acc
      end
    end)
  end

  defp normalize_with_additional_lookups(materials, token) do
    {google_materials, other_materials} =
      Enum.split_with(materials, fn {type, _, _} -> type in [:google_doc, :google_slide, :google_file] end)
    google_materials
    |> renormalize_and_add_details_to_google_materials(token)
    |> R.map(&(other_materials ++ &1))
  end

  defunp renormalize_and_add_details_to_google_materials(google_materials :: [material_t], token :: Google.token_t) :: R.t([material_t]) do
    batch_get_details(google_materials, token)
    |> R.bind(fn
      get_detail_results when length(get_detail_results) == length(google_materials) ->
        google_materials
        |> Enum.zip(get_detail_results)
        |> Enum.map(&renormalize_and_add_details_impl/1)
        |> Enum.reject(&is_nil/1)
        |> R.pure()
      results ->
        Blick.Logger.error("Insufficient Google.Drive.Files.batch_get/2 results. Got: #{inspect(results)}")
        {:error, :batch_get_files_missing_some_response}
    end)
  end

  defp batch_get_details(google_materials, token) do
    google_materials
    |> Enum.map(fn
      {:google_doc, "https://docs.google.com/document/d/" <> file_id, _title} -> file_id
      {:google_slide, "https://docs.google.com/presentation/d/" <> file_id, _title} -> file_id
      {:google_file, "https://drive.google.com/file/d/" <> file_id, _title} -> file_id
    end)
    |> Files.batch_get(token)
  end

  defp renormalize_and_add_details_impl({{_type, _url, _title}, {404, _resp_body}}) do
    nil
  end
  defp renormalize_and_add_details_impl({original_material, {403, %{"error" => %{"errors" => [%{"domain" => "usageLimits"} | _]}}}}) do
    Blick.Logger.debug("Rate Limit on: #{inspect(original_material)}")
    original_material
  end
  defp renormalize_and_add_details_impl({{:google_slide, url, title}, {200, file}}) do
    {_file_id, "application/vnd.google-apps.presentation", thumbnail_url, author_email} = details(file)
    {:google_slide, url, title, author_email, thumbnail_url}
  end
  defp renormalize_and_add_details_impl({{:google_doc, url, title}, {200, file}}) do
    {_file_id, "application/vnd.google-apps.document", thumbnail_url, author_email} = details(file)
    {:google_doc, url, title, author_email, thumbnail_url}
  end
  defp renormalize_and_add_details_impl({{:google_file, _url, title}, {200, file}}) do
    {file_id, mimetype, thumbnail_url, author_email} = details(file)
    case mimetype do
      "application/vnd.google-apps.presentation" ->
        {:google_slide, "https://docs.google.com/presentation/d/#{file_id}", title, author_email, thumbnail_url}
      "application/vnd.google-apps.document" ->
        {:google_doc, "https://docs.google.com/document/d/#{file_id}", title, author_email, thumbnail_url}
      _misc_mimetypes ->
        {:google_file, "https://docs.google.com/file/d/#{file_id}", title, author_email, thumbnail_url}
    end
  end

  defp details(%{"id" => file_id,
                 "mimeType" => mimetype,
                 "owners" => [%{"emailAddress" => author_email} | _]} = file) do
    {file_id, mimetype, enlarge_thumbnail_size(file["thumbnailLink"]), author_email}
  end

  defp enlarge_thumbnail_size(nil), do: nil
  defp enlarge_thumbnail_size(url) when is_binary(url), do: String.replace(url, "=s220", "=s640") # Yes, it's cheesy
end
