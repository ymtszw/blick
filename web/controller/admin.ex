use Croma

defmodule Blick.Controller.Admin do
  use SolomonLib.Controller
  alias Croma.Result, as: R
  alias SolomonLib.Time
  alias GearLib.Oauth2
  alias Blick.Repo

  plug Blick.Plug.Auth, :filter_by_sender_identity, []

  def authorize(conn) do
    render_with_params(conn, Blick.Plug.Auth.admin())
  end

  defp render_with_params(conn, admin) do
    params = [
      admin: admin,
      authorize_url: authorize_url!(conn.context.start_time)
    ]
    render(conn, 200, "authorize", params, layout: :admin)
  end

  defp authorize_url!(start_time) do
    Oauth2.authorize_url!(Repo.AdminToken.client(), [
      access_type: "offline",
      prompt: "consent",
      scope:
        [
          "openid",
          "email",
          "profile",
          "https://www.googleapis.com/auth/drive.readonly",
          "https://www.googleapis.com/auth/spreadsheets.readonly",
          "https://www.googleapis.com/auth/presentations.readonly",
          "https://www.googleapis.com/auth/contacts.readonly",
        ] |> Enum.join(" "),
      state:
        start_time
        |> Time.to_iso_timestamp()
        |> Blick.encrypt_base64!(),
    ])
  end

  def authorize_callback(conn) do
    case conn.request.headers["x-forwarded-host"] do
      "localhost:8079" <> _ ->
        # Via webpack-dev-server proxy; rerouting to gear host
        redirect(conn, "http://blick.localhost:8080" <> Blick.Router.callback_path() <> "?" <> URI.encode_query(conn.request.query_params))
      _ ->
        authorize_callback_impl(conn)
    end
  end

  defp authorize_callback_impl(conn) do
    case verify_state(conn.request.query_params["state"], conn.context.start_time) do
      {:ok, :verified} ->
        handle_callback_params(conn, conn.request.query_params)
      {:error, _} = e ->
        Blick.Logger.debug("Invalid request to callback path. Got: " <> inspect(e))
        redirect(conn, Blick.Router.authorize_path())
    end
  end

  @verifyable_window_in_seconds 60

  defp verify_state(nil, _start_time) do
    {:error, :invalid_state}
  end
  defp verify_state(state, start_time) do
    R.m do
      decrypted <- Blick.decrypt_base64(state)
      time <- Time.from_iso_timestamp(decrypted)
      if Time.shift_seconds(time, @verifyable_window_in_seconds) > start_time do
        {:ok, :verified}
      else
        {:error, {:timeout, time, start_time}}
      end
    end
  end

  defp handle_callback_params(conn, %{"code" => code}) do
    case Repo.AdminToken.retrieve_token_and_save(code) do
      {:ok, admin_token} ->
        render_with_params(conn, admin_token.data.owner)
      otherwise ->
        Blick.Logger.error("Something went wrong on Admin authorization. Got: " <> inspect(otherwise))
        redirect(conn, Blick.Router.authorize_path())
    end
  end
  defp handle_callback_params(conn, %{"error" => "access_denied"}) do
    redirect(conn, Blick.Router.authorize_path())
  end
  defp handle_callback_params(conn, params) do
    Blick.Logger.debug("Unusual response params from Google. Got: " <> inspect(params))
    redirect(conn, Blick.Router.authorize_path())
  end
end
