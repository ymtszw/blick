defmodule Blick.Controller.Root do
  alias Croma.Result, as: R
  use SolomonLib.Controller
  import Blick.Dodai, only: [root_key: 0]
  alias Blick.Repo
  alias Blick.Model.Material

  plug Blick.Plug.Auth, :filter_by_sender_identity, [], except: [:public_login]
  plug Blick.Plug.Auth, :ensure_admin_authorization, [], except: [:public_login]

  def public_login(conn) do
    json(conn, 403, %{"error" => "Access from public network is under development"})
  end

  def index(conn) do
    render_with_20_materials(conn)
  end

  defp render_with_20_materials(conn, _material \\ nil) do
    render(conn, 200, "root", [
      title: "Blick",
      description: "ACCESSの勉強会資料ポータルサイト",
      url: SolomonLib.Env.default_base_url(:blick),
      thumbnail: Blick.Asset.url("img/blick_480.png"),
      flags: first_20_in_kvs(root_key()),
    ])
  end

  defp first_20_in_kvs(key) do
    %{limit: 20}
    |> Repo.Material.only_included()
    |> Repo.Material.retrieve_list(key)
    |> R.get([])
    |> Map.new(fn m -> {m._id, m} end)
  end

  def show(conn) do
    id_in_path = conn.request.path_matches.id
    if Material.Id.valid?(id_in_path) do
      show_impl(conn, id_in_path)
    else
      # Handles favicon.ico, robot.txt, etc...
      put_status(conn, 404)
    end
  end

  defp show_impl(conn, id) do
    case Repo.Material.retrieve_with_refresh(id, root_key(), conn.context.start_time) do
      {:ok, m} ->
        render_with_20_materials(conn, m)
      {:error, _} ->
        fallback(conn)
    end
  end

  def fallback(conn), do: redirect(conn, "/")
end
