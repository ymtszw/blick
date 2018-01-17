defmodule Blick.External.Google do
  alias Croma.Result, as: R
  alias SolomonLib.Httpc
  alias Blick.Model.AdminToken

  @type token_t :: AdminToken.t | String.t

  @spec with_token(token :: token_t, api_fun :: (String.t -> R.t(x))) :: R.t(x) when x: any
  def with_token(%AdminToken{data: %AdminToken.Data{access_token: %Blick.SecretString{value: at}}}, api_fun) do
    api_fun.(at)
  end
  def with_token(access_token, api_fun) when is_binary(access_token) do
    api_fun.(access_token)
  end

  def handle_200(%Httpc.Response{status: 200, body: res_body}) do
    {:ok, Poison.decode!(res_body)}
  end
  def handle_200(%Httpc.Response{status: code, body: res_body}) do
    {:error, {code, res_body}}
  end
end
