use Croma

defmodule Blick.Controller.Material do
  use SolomonLib.Controller
  alias Blick.Repo
  alias Blick.Model.Material

  plug Blick.Plug.Auth, :authenticate_by_sender, []

  defun list(%Conn{request: _req, assigns: %{key: key}} = conn) :: Conn.t do
    query = Repo.Material.only_included(%{})
    case Repo.Material.retrieve_list(query, key) do
      {:ok, ms} ->
        json(conn, 200, %{"materials" => Map.new(ms, fn m -> {m._id, m} end)}) # Pass in KVS
      {:error, %_error{status_code: code, body: body}} ->
        json(conn, code, body)
    end
  end

  defun get(%Conn{request: req, assigns: %{key: key}} = conn) :: Conn.t do
    case Repo.Material.retrieve_with_refresh(req.path_matches.id, key, conn.context.start_time) do
      {:ok, %Material{} = material} ->
        json(conn, 200, material)
      {:error, %_error{status_code: code, body: body}} ->
        json(conn, code, body)
    end
  end
end
