use Croma

defmodule Blick.AsyncJob.MaterialCollecter do
  alias Croma.Result, as: R
  alias Blick.External.Google.Spreadsheets
  alias Blick.Model.Material

  @type material_t :: {Material.Type.t, SolomonLib.Url.t, String.t}

  @rnd_seminar_spreadsheet_id "1j-ag_0n1CyLAjOTNA5bVYuCN4uq-UbFKYavU4dvh1G8"
  @doc """
  Collect materials from (now-defunct) RnD seminar schedule spreadsheet.

  Results are in list of `material_t`.
  """
  defun collect_materials_from_rnd_seminar_spreadsheet(token :: Blick.External.Google.token_t) :: R.t([material_t]) do
    R.m do
      file <- Spreadsheets.get(@rnd_seminar_spreadsheet_id, token) # This can take a few seconds
      schedule_sheets <- get_shedule_sheets(file["sheets"] || [])
      materials = parse_schedule_sheets(schedule_sheets)
      pure normalize_with_additional_lookups(materials)
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

  defp normalize_with_additional_lookups(materials) do
    # TODO
    materials
  end
end
