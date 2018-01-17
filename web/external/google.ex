use Croma

defmodule Blick.External.Google do
  alias Croma.Result, as: R
  alias SolomonLib.{Httpc, Url}
  alias SolomonLib.Http.{Method, Headers}
  alias Blick.Model.AdminToken

  @type token_t :: AdminToken.t | String.t
  @type res_t :: R.t(:no_content | map, Httpc.Response.t)

  defun request(token :: token_t,
                method :: v[Method.t],
                url :: v[Url.t],
                body :: v[Httpc.ReqBody.t] \\ "",
                headers :: v[Headers.t] \\ %{},
                opts :: Keyword.t \\ []) :: res_t do
    at = access_token(token)
    authorized_headers = Map.merge(%{"authorization" => "Bearer #{at}"}, headers) # Allow overriding Authorization header by caller
    Httpc.request(method, url, body, authorized_headers, opts)
    |> R.bind(&handle_res/1)
  end

  def access_token(%AdminToken{data: data}), do: data.access_token.value
  def access_token(str) when is_binary(str), do: str

  defun handle_res(res :: Httpc.Response.t) :: res_t do
    %Httpc.Response{status: 204} ->
      {:ok, :no_content}
    %Httpc.Response{status: code, body: res_body} when code in 200..299 ->
      {:ok, Poison.decode!(res_body)}
    res ->
      {:error, res}
  end
end
