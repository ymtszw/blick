use Croma

defmodule Blick.Controller.Material do
  alias Croma.Result, as: R
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

  drop_tuple = fn
    {mod, _} when is_atom(mod) -> mod
    mod when is_atom(mod) -> mod
  end
  for {field, croma_type0} <- Material.data_fields(), croma_type1 = drop_tuple.(croma_type0) do
    def unquote(:"update_#{field}")(conn) do
      validate_and_put_value(conn, unquote(field), unquote(croma_type1))
    end
  end

  defp validate_and_put_value(%Conn{request: req, assigns: %{key: key}} = conn, field, croma_type) do
    R.m do
      id <- R.wrap_if_valid(req.path_matches.id, Material.Id)
      value <- validate_body(req.body, croma_type)
      Repo.Material.update(%{data: %{"$set" => %{field => value}}}, id, key)
    end
    |> case do
      {:ok, %Material{} = material} ->
        json(conn, 200, material)
      {:error, %_error{status_code: code, body: body}} ->
        json(conn, code, body)
      {:error, _} ->
        json(conn, 400, %{error: "BadRequest"})
    end
  end

  defp validate_body(%{"value" => v}, croma_type), do: R.wrap_if_valid(v, croma_type)
  defp validate_body(_invalid_body, _croma_type), do: {:error, :bad_request}
end
