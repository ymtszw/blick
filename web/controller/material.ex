use Croma

defmodule Blick.Controller.Material do
  alias Croma.Result, as: R
  use SolomonLib.Controller
  import Blick.Dodai, only: [root_key: 0]
  alias Blick.External.Google.Drive.Files
  alias Blick.Repo
  alias Blick.Model.Material
  alias Blick.AsyncJob.{MaterialRefresher, AsyncRepo}

  plug Blick.Plug.Auth, :filter_by_sender_identity, []
  plug Blick.Plug.Auth, :ensure_admin_authorization, []

  defun list(%Conn{request: _req} = conn) :: Conn.t do
    query = Repo.Material.only_included(%{})
    case Repo.Material.retrieve_list(query, root_key()) do
      {:ok, ms} ->
        conn
        |> put_resp_header("cache-control", "private,max-age=3600")
        |> json(200, %{"materials" => ms})
      {:error, %_error{status_code: code, body: body}} ->
        json(conn, code, body)
    end
  end

  defun get(%Conn{request: req} = conn) :: Conn.t do
    root_key = root_key()
    threshold = SolomonLib.Time.shift_minutes(conn.context.start_time, -20)
    case Repo.Material.retrieve(req.path_matches.id, root_key) do
      {:ok, %Material{data: %Material.Data{excluded: true}}} ->
        json(conn, 404, %{"error" => "Not Found"})
      {:ok, %Material{updated_at: updated_at} = material} when updated_at < threshold ->
        json(conn, 200, refresh_and_write_back(material, root_key))
      {:ok, %Material{} = material} ->
        json(conn, 200, material)
      {:error, %_error{status_code: code, body: body}} ->
        json(conn, code, body)
    end
  end

  defp refresh_and_write_back(%Material{data: %Material.Data{type: type}} = old_material, key)
  when type in [:google_doc, :google_file, :google_slide] do
    case refresh_google_file_and_write_back(old_material, key) do
      {:ok, new_material} -> new_material
      {:error, _} -> old_material
    end
  end
  defp refresh_and_write_back(other_material, _key) do
    other_material
  end

  defp refresh_google_file_and_write_back(%Material{} = material, key) do
    R.m do
      token <- Repo.AdminToken.retrieve()
      code_and_body <- get_file(Material.google_file_id!(material), token)
      case MaterialRefresher.make_update_action({material, code_and_body}) do
        nil ->
          {:ok, material}
        {id, %{data: %{"$set" => %{thumbnail_url: new_url}}} = ua} ->
          # XXX; This is just an experimental pattern of write back.
          # I think update request to Dodai is fast enough and does not require background task usually.
          AsyncRepo.Material.update(ua, id, key)
          {:ok, put_in(material.data.thumbnail_url, new_url)}
      end
    end
  end

  defp get_file(file_id, token) do
    case Files.get(file_id, token) do
      {:ok, file} ->
        {:ok, {200, file}}
      {:error, %{code: code, body: res_body}} when code in 400..499 ->
        {:ok, {code, Poison.decode!(res_body)}}
      {:error, _} = e ->
        e
    end
  end
end
