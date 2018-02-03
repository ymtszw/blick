use Croma

defmodule Blick.Controller.Material do
  use SolomonLib.Controller
  import Blick.Dodai, only: [root_key: 0]
  alias Blick.Repo

  plug Blick.Plug.Auth, :filter_by_sender_identity, []
  plug Blick.Plug.Auth, :ensure_admin_authorization, []

  defun list(%Conn{request: _req} = conn) :: Conn.t do
    root_key = root_key()
    query = Repo.Material.only_included(%{})
    case Repo.Material.retrieve_list(query, root_key) do
      {:ok, ms} ->
        conn
        |> put_resp_header("cache-control", "private,max-age=3600")
        |> json(200, %{"materials" => ms})
      {:error, %_error{status_code: code, body: body}} ->
        json(conn, code, body)
    end
  end
end
