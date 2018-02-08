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
    render(conn, 200, "root", [
      title: "Blick",
      description: "ACCESSの勉強会資料ポータルサイト",
      url: SolomonLib.Env.default_base_url(:blick),
      thumbnail: Blick.Asset.url("img/blick_480.png"),
      flags: retrieve_list_20(root_key()),
    ])
  end

  defp retrieve_list_20(key) do
    %{limit: 20}
    |> Repo.Material.only_included()
    |> Repo.Material.retrieve_list(key)
    |> R.get([])
  end

  def show(conn) do
    id_in_path = conn.request.path_matches.id
    if Material.Id.valid?(id_in_path) do
      # TODO
      index(conn)
    else
      # Handles favicon.ico, robot.txt, etc...
      put_status(conn, 404)
    end
  end

  def fallback(conn), do: redirect(conn, "/")
end
