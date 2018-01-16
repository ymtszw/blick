defmodule Blick.Controller.Admin do
  use SolomonLib.Controller
  alias SolomonLib.Time
  alias GearLib.Oauth2
  alias GearLib.Oauth2.Provider.Google

  plug Blick.Plug.Auth, :filter_by_sender_identity, []

  # GET /admin/authorize
  def authorize(conn) do
    render_with_params(conn, false)
    # TODO
    # 1. Establish admin access_token and refresh_token storage (model?)
    # 3. Check admin authorization status and if not authorized, render instruction page
    # 4. If authorized page, inform that
  end

  defp render_with_params(conn, authorized?) do
    params = [
      authorized?: authorized?,
      authorize_url: authorize_url!(conn.context.start_time)
    ]
    render(conn, 200, "authorize", params, layout: :admin)
  end

  defp authorize_url!(start_time) do
    Oauth2.authorize_url!(client(), [
      access_type: "offline",
      prompt: "consent",
      scope:
        [
          "https://www.googleapis.com/auth/userinfo.profile",
          "https://www.googleapis.com/auth/userinfo.email",
        ] |> Enum.join(" "),
      state:
        start_time
        |> Time.to_iso_timestamp()
        |> Blick.encrypt_base64(),
    ])
  end

  # GET /admin/authorize_callback
  def authorize_callback(conn) do
    case conn.request.headers["x-forwarded-host"] do
      "localhost:8081" <> _ ->
        # Via webpack-dev-server proxy; rerouting to gear host
        redirect(conn, "http://blick.localhost:8080" <> Blick.Router.callback_path() <> "?" <> URI.encode_query(conn.request.query_params))
      _ ->
        authorize_callback_impl(conn)
    end
  end

  defp authorize_callback_impl(conn) do
    case Oauth2.code_to_token(client(), conn.request.query_params["code"], []) do
      {:ok, %OAuth2.AccessToken{access_token: at, refresh_token: rt}} when byte_size(at) > 0 and byte_size(rt) > 0 ->
        render_with_params(conn, true)
      otherwise ->
        redirect(conn, Blick.Router.authorize_path())
    end
  end

  # Internals

  defp client() do
    %{"google_client_id" => id, "google_client_secret" => secret} = Blick.get_all_env()
    Google.client(id, secret, redirect_url())
  end

  if SolomonLib.Env.compiling_for_cloud?() do
    defp redirect_url(), do: SolomonLib.Env.default_base_url(:blick) <> Blick.Router.callback_path()
  else
    # Google only allows "http://localhost" for local development.
    # webpack-dev-server's (http-proxy-middleware's) proxy function will redirect to gear
    defp redirect_url(), do: "http://localhost:8081" <> Blick.Router.callback_path()
  end
end
