use Croma

defmodule Blick.Controller.Material do
  use SolomonLib.Controller
  import Blick.Dodai, only: [root_key: 0]
  alias Blick.Repo
  alias Blick.Model.Material

  plug Blick.Plug.Auth, :authenticate_by_sender, []

  defun list(%Conn{request: _req} = conn) :: Conn.t do
    query = Repo.Material.only_included(%{})
    case Repo.Material.retrieve_list(query, root_key()) do
      {:ok, ms} ->
        json(conn, 200, %{"materials" => Map.new(ms, fn m -> {m._id, m} end)}) # Pass in KVS
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
