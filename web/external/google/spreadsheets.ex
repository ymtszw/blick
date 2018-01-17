use Croma

defmodule Blick.External.Google.Spreadsheets do
  @moduledoc """
  Binding for Google Spreadsheets API.
  """

  alias Blick.External.Google

  @base_url "https://sheets.googleapis.com/v4"

  defun get(id :: v[String.t], token :: Google.token_t) :: Google.res_t do
    Google.request(token, :get, @base_url <> "/spreadsheets/#{id}", "", %{}, params: %{"includeGridData" => true})
  end

  Croma.Result.define_bang_version_of(get: 2)
end
