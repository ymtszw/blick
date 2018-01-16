use Croma

defmodule Blick.Repo.AdminToken do
  @moduledoc """
  Repository of AdminToken.

  AdminToken is basically a Google OAuth2 access_token with somewhat broad read scopes and offline access.
  It must be unique in the environment, and refreshed using refresh_token before expiration.
  """

  alias OAuth2.AccessToken
  alias SolomonLib.Time
  alias GearLib.Oauth2
  alias GearLib.Oauth2.Provider.Google
  import Blick.Dodai, only: [root_key: 0]
  alias Blick.Model.AdminToken
  alias Blick.External.Google.People
  use SolomonAcs.Dodai.Repo.Datastore, [
    datastore_models: [AdminToken],
    read_permission:  :root,
    write_permission: :root,
  ]

  # Convenient CRUD APIs

  def upsert(%AccessToken{access_token: at, expires_at: ea, refresh_token: rt}, email) do
    data =
      AdminToken.Data.new!(%{
        access_token: %{value: at},
        refresh_token: %{value: rt},
        expires_at: SolomonLib.Time.from_epoch_milliseconds(ea * 1_000),
        owner: email,
      })
    upsert(%{data: %{"$set" => data}, data_on_insert: data}, AdminToken.id(), root_key())
  end

  def retrieve_token_and_save(code) do
    case Oauth2.code_to_token(client(), code, []) do
      {:ok, %AccessToken{access_token: at, refresh_token: rt} = oat} when byte_size(at) > 0 and byte_size(rt) > 0 ->
        Croma.Result.bind(ensure_admin_domain(at), fn email -> upsert(oat, email) end)
      otherwise ->
        Blick.Logger.error("Could not retrieve sufficient AccessToken. Got: " <> inspect(otherwise))
        {:error, :insufficient_access_token}
    end
  end

  @admin_domain "@access-company.com"

  defp ensure_admin_domain(access_token) do
    case People.me(access_token) do
      {:ok, %{"emailAddresses" => [%{"value" => email} | _]}} ->
        if String.ends_with?(email, @admin_domain) do
          {:ok, email}
        else
          {:error, :invalid_domain}
        end
      otherwise ->
        Blick.Logger.error("Could not retrieve authorizing user's identity. Got: " <> inspect(otherwise))
        {:error, :google_api_error}
    end
  end

  def update(%AccessToken{access_token: at, expires_at: ea, refresh_token: rt}) do
    %{data: %{"$set" =>
      AdminToken.Data.new!(%{
        access_token: %{value: at},
        refresh_token: %{value: rt},
        expires_at: SolomonLib.Time.from_epoch_milliseconds(ea * 1_000),
      })
    }}
    |> update(AdminToken.id(), root_key())
  end

  def retrieve() do
    case retrieve(AdminToken.id(), root_key()) do
      {:ok, %AdminToken{} = at} ->
        now = Time.now()
        if AdminToken.expired?(at, now) do
          refresh_token_and_update(at, now)
        else
          refresh_preemptively_if_lucky(at, now)
        end
      error ->
        error
    end
  end

  def revoke(), do: delete(AdminToken.id(), nil, root_key())

  # Admin OAuth2 client

  def client() do
    %{"google_client_id" => id, "google_client_secret" => secret} = Blick.get_all_env()
    Google.client(id, secret, redirect_url())
  end

  # Internals

  if SolomonLib.Env.compiling_for_cloud?() do
    defp redirect_url(), do: SolomonLib.Env.default_base_url(:blick) <> Blick.Router.callback_path()
  else
    # Google only allows "http://localhost" for local development.
    # webpack-dev-server's (http-proxy-middleware's) proxy function will redirect to gear
    defp redirect_url(), do: "http://localhost:8081" <> Blick.Router.callback_path()
  end

  defp refresh_token_and_update(%AdminToken{data: %AdminToken.Data{expires_at: ea, refresh_token: rt}}, now) do
    log_refresh(ea, now)
    case Oauth2.refresh(client(), rt.value, grant_type: "refresh_token") do
      {:ok, %AccessToken{access_token: at, refresh_token: rt} = oat} when byte_size(at) > 0 and byte_size(rt) > 0 ->
        update(oat)
      otherwise ->
        Blick.Logger.error("Failed to refresh AccessToken. Got: " <> inspect(otherwise))
        {:error, :refresh_failure}
    end
  end

  defp log_refresh(expires_at, now) do
    diff = Time.diff_milliseconds(expires_at, now)
    Blick.Logger.info("Refreshing AdminToken. expires_at: #{inspect(expires_at)} (#{diff}ms)")
  end

  @leeway_second_mean 600
  @leeway_second_variance 200

  defp refresh_preemptively_if_lucky(%AdminToken{data: %AdminToken.Data{expires_at: ea}} = at, now) do
    leeway_seconds = round(:rand.normal(@leeway_second_mean, @leeway_second_variance))
    if Time.shift_seconds(now, leeway_seconds) >= ea do
      refresh_token_and_update(at, now)
    else
      {:ok, at}
    end
  end
end
