defmodule Blick.Controller.Hello do
  use SolomonLib.Controller

  def hello(conn) do
    Blick.Gettext.put_locale(conn.request.query_params["locale"] || "en")
    render(conn, 200, "hello", [gear_name: :blick])
  end
end
