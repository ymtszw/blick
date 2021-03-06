defmodule Blick.Controller.Root do
  alias Croma.Result, as: R
  use Antikythera.Controller
  alias Blick.Repo
  alias Blick.Model.Material

  plug Blick.Plug.Auth, :authenticate_by_sender, [], except: [:public_login]
  plug Blick.Plug.Auth, :ensure_admin_authorization, [], except: [:public_login]

  def public_login(conn) do
    Conn.json(conn, 403, %{"error" => "Access from public network is under development"})
  end

  def index(conn) do
    render_with_20_materials(conn, false)
  end

  defp render_with_20_materials(%Conn{assigns: %{key: key}} = conn, clipped?, pair \\ %{}) do
    document_class = if clipped?, do: "is-clipped", else: ""
    Conn.render(conn, 200, "root", [
      document_class: document_class,
      title: "Blick",
      description: "ACCESSの勉強会資料ポータルサイト",
      url: Antikythera.Env.default_base_url(:blick),
      thumbnail: Blick.Asset.url("img/blick_480.png"),
      flags: first_20_in_kvs(key) |> Map.merge(pair),
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
      Conn.put_status(conn, 404)
    end
  end

  defp show_impl(%Conn{assigns: %{key: key}} = conn, id) do
    case Repo.Material.retrieve_with_refresh(id, key, conn.context.start_time) do
      {:ok, %Material{_id: id} = m} ->
        render_with_20_materials(conn, true, %{id => m})
      {:error, _} ->
        fallback(conn)
    end
  end

  def fallback(conn), do: Conn.redirect(conn, "/")
end
