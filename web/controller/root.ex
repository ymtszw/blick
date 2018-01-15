defmodule Blick.Controller.Root do
  use SolomonLib.Controller

  def index(conn) do
    render(conn, 200, "root", [
      title: "Blick",
      path: conn.request.path_matches[:path],
    ])
  end
end
