use Croma

defmodule Blick.AsyncJob.MaterialCollecter do
  alias Croma.Result, as: R
  alias Blick.External.Google.Spreadsheets

  @rnd_seminar_spreadsheet_id "1j-ag_0n1CyLAjOTNA5bVYuCN4uq-UbFKYavU4dvh1G8"
  def rnd_seminar_spreadsheet_id(), do: @rnd_seminar_spreadsheet_id

  def collect_material_urls_from_spreadsheet(token) do
    R.m do
      file <- Spreadsheets.get(@rnd_seminar_spreadsheet_id, token) # This can take a few seconds
      schedule_sheets <- get_shedule_sheets(file["sheets"] || [])
      pure parse_schedule_sheets(schedule_sheets)
    end
  end

  defp get_shedule_sheets(sheets) do
    case Enum.reverse(sheets) do
      [_dice_roll_sheet | schedule_sheets] -> {:ok, schedule_sheets}
      _ -> {:error, :unexpected_sheet_format}
    end
  end

  defp parse_schedule_sheets(schedule_sheets) do
    schedule_sheets |> Enum.flat_map(&parse_sheet/1) |> take_sample()
  end

  if SolomonLib.Env.compiling_for_cloud?() do
    defp take_sample(results), do: results
  else
    @sample_count 20
    defp take_sample(results), do: results |> Enum.shuffle() |> Enum.take(@sample_count)
  end

  defp parse_sheet(%{"data" => grid_data_list}) do
    Enum.flat_map(grid_data_list, &parse_grid_data/1)
  end

  defp parse_grid_data(%{"rowData" => row_data_list}) do
    Enum.flat_map(row_data_list, &parse_row_data/1)
  end

  @excluded_urls [
    "https://drive.google.com/a/access-company.com/?tab=oo#folders/0B6DpgpRl_A1mfl9VblV6Rlk0TTM2YmlmYVYtUDE0VWo3ZmZ0b3BMSk55clRnYXMwN3h4N2c", # Material directory URL
  ]

  defp parse_row_data(%{"values" => cell_data_list}) do
    Enum.reduce(cell_data_list, [], fn cell, acc ->
      case cell["hyperlink"] do
        "http" <> _ = url when not url in @excluded_urls ->
          [{url, cell["formattedValue"] || url} | acc]
        _ ->
          acc
      end
    end)
  end
end
