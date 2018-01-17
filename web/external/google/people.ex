use Croma

defmodule Blick.External.Google.People do
  @moduledoc """
  Binding for Google People API.
  """

  alias Croma.Result, as: R
  alias SolomonLib.Httpc
  alias Blick.External.Google

  @people_api_url "https://people.googleapis.com/v1"

  defun me(token :: Google.token_t) :: R.t(map) do
    Google.with_token(token, &me_impl/1)
  end

  defunp me_impl(token :: v[String.t]) :: R.t(map) do
    R.m do
      header = %{"authorization" => "Bearer #{token}"}
      params = %{"personFields" => "emailAddresses,memberships,organizations"}
      response <- Httpc.get(@people_api_url <> "/people/me", header, params: params)
      me_response(response)
    end
  end

  defp me_response(%Httpc.Response{status: 200, body: res_body}) do
    {:ok, Poison.decode!(res_body)}
  end
  defp me_response(%Httpc.Response{status: code, body: res_body}) do
    {:error, {code, res_body}}
  end
end
