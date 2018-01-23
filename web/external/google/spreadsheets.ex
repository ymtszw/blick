use Croma

defmodule Blick.External.Google.Spreadsheets do
  @moduledoc """
  Binding for Google Spreadsheets API.
  """

  alias Blick.External.Google

  @base_url "https://sheets.googleapis.com/v4"

  @doc """
  Retrieves a spreadsheet.

  This can take some time if the targeted spreadsheet is somehow large.
  """
  defun get(id :: v[String.t], token :: Google.token_t) :: Google.res_t do
    Blick.with_logging_elapsed("Spreadsheet retrieved in:", fn ->
      Google.request(token, :get, @base_url <> "/spreadsheets/#{id}", "", %{}, params: %{"includeGridData" => true})
    end)
  end

  Croma.Result.define_bang_version_of(get: 2)
end
