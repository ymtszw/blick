use Croma

defmodule Blick.Controller.Material do
  use SolomonLib.Controller
  import Blick.Dodai, only: [root_key: 0]
  alias Blick.Repo
  alias Blick.Model.Material

  plug Blick.Plug.Auth, :filter_by_sender_identity, []
  plug Blick.Plug.Auth, :ensure_admin_authorization, []

  defun list(%Conn{request: _req} = conn) :: Conn.t do
    query = Repo.Material.only_included(%{})
    case Repo.Material.retrieve_list(query, root_key()) do
      {:ok, ms} ->
        conn
        |> put_resp_header("cache-control", "private,max-age=1800")
        |> json(200, %{"materials" => ms})
      {:error, %_error{status_code: code, body: body}} ->
        json(conn, code, body)
    end
  end

  defun get(%Conn{request: req} = conn) :: Conn.t do
    root_key = root_key()
    case Repo.Material.retrieve_with_refresh(req.path_matches.id, root_key, conn.context.start_time) do
      {:ok, %Material{} = material} ->
        json(conn, 200, material)
      {:error, %_error{status_code: code, body: body}} ->
        json(conn, code, body)
    end
  end
end
