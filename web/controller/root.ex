defmodule Blick.Controller.Root do
  use SolomonLib.Controller

  plug Blick.Plug.Auth, :filter_by_sender_identity, [], only: [:index]

  # GET /login
  def public_login(conn) do
    json(conn, 403, %{"error" => "Access from public network is under development"})
  end

  # GET /
  def index(conn) do
    render(conn, 200, "root", [
      title: "Blick",
    ])
  end
end
