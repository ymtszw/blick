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
  alias Blick.SecretString, as: SS
  import Blick.Dodai, only: [root_key: 0]
  alias Blick.Model.AdminToken
  alias Blick.External.Google.OpenidConnect
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
        Croma.Result.bind(ensure_admin_domain(oat), fn email -> upsert(oat, email) end)
      otherwise ->
        Blick.Logger.error("Could not retrieve sufficient AccessToken. Got: " <> inspect(otherwise))
        {:error, :insufficient_access_token}
    end
  end

  @admin_domain "access-company.com"

  defp ensure_admin_domain(%AccessToken{other_params: %{"id_token" => id_token}}) do # Warned by dialyzer; PRing on https://github.com/scrogson/oauth2/pull/105
    case OpenidConnect.parse_and_verify_id_token(id_token) do
      {:ok, %{"email" => email, "hd" => @admin_domain}} ->
        {:ok, email}
      otherwise ->
        Blick.Logger.error("Could not verify authorizing user's identity. Got: " <> inspect(otherwise))
        {:error, :invalid_id_token}
    end
  end
  defp ensure_admin_domain(otherwise) do
    Blick.Logger.error("Could not retrieve authorizing user's identity. Got: " <> inspect(otherwise))
    {:error, :id_token_not_found}
  end

  def update(%AccessToken{access_token: at, expires_at: ea, refresh_token: rt}) do
    data =
      %{
        access_token: %SS{value: at},
        refresh_token: %SS{value: rt},
        expires_at: SolomonLib.Time.from_epoch_milliseconds(ea * 1_000),
      }
    update(%{data: %{"$set" => data}}, AdminToken.id(), root_key())
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

  Croma.Result.define_bang_version_of([retrieve: 0])

  def revoke(group_id \\ Blick.Dodai.default_group_id()), do: delete(AdminToken.id(), nil, root_key(), group_id)

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
    Blick.Logger.info("Refreshing AdminToken. expires_at: #{inspect(expires_at)} (#{div(diff, 1_000)}s)")
  end

  @leeway_second_mean 600
  @leeway_second_variance 200

  defp refresh_preemptively_if_lucky(%AdminToken{data: %AdminToken.Data{expires_at: ea}} = at, now) do
    leeway_seconds = round(:rand.normal(@leeway_second_mean, @leeway_second_variance))
    Blick.Logger.debug("Leeway this round: #{leeway_seconds}s")
    Blick.Logger.debug("Expires in: #{div(Time.diff_milliseconds(ea, now), 1_000)}s")
    if Time.shift_seconds(now, leeway_seconds) >= ea do
      refresh_token_and_update(at, now)
    else
      {:ok, at}
    end
  end
end
