use Croma

defmodule Blick.External.Google.People do
  @moduledoc """
  Binding for Google People API.
  """

  alias Croma.Result, as: R
  alias SolomonLib.Httpc
  alias Blick.External.Google

  @base_url "https://people.googleapis.com/v1"

  defun me(token :: Google.token_t) :: R.t(map) do
    Google.with_token(token, fn at ->
      header = %{"authorization" => "Bearer #{at}"}
      params = %{"personFields" => "emailAddresses,memberships,organizations"}
      Httpc.get(@base_url <> "/people/me", header, params: params)
      |> R.bind(&Google.handle_200/1)
    end)
  end
end
