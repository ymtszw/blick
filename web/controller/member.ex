defmodule Blick.Controller.Member do
  use SolomonLib.Controller
  alias Blick.Repo
  alias Blick.Model.MemberCache

  plug Blick.Plug.Auth, :authenticate_by_sender, []

  @max_age Repo.MemberCache.expires_in_minute()

  def list(%Conn{assigns: %{key: key}} = conn) do
    case Repo.MemberCache.retrieve_with_refresh(key) do
      {:ok, %MemberCache{data: %MemberCache.Data{list: members}}} ->
        conn
        |> put_resp_header("cache-control", "private, max-age=#{@max_age}")
        |> json(200, %{members: members})
      {:error, %_error_struct{status_code: code, body: body}} ->
        json(conn, code, body)
    end
  end
end
