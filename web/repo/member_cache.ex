use Croma

defmodule Blick.Model.MemberCache do
  @id "global_cache"
  def id(), do: @id

  use SolomonAcs.Dodai.Model.Datastore, [
    id_pattern: ~r/\A#{@id}\Z/,
    data_fields: [
      list: Croma.TypeGen.list_of(SolomonLib.Email)
    ]
  ]
end

defmodule Blick.Repo.MemberCache do
  @moduledoc """
  Cache of organization member email list.
  """

  alias Croma.Result, as: R
  alias SolomonLib.Time
  alias Blick.Model.MemberCache
  alias Blick.External.Google.Directory.Users
  alias Blick.Repo.AdminToken
  use SolomonAcs.Dodai.Repo.Datastore, [
    datastore_models: [MemberCache],
  ]

  defun retrieve() :: R.t(MemberCache.t) do
    Blick.with_logging_elapsed("Retrieved MemberCache:", fn ->
      root_key = Blick.Dodai.root_key()
      case retrieve(MemberCache.id(), root_key) do
        {:ok, mc} ->
          refresh_if_expiring(mc, root_key)
        {:error, %Dodai.ResourceNotFound{}} ->
          ensure_global_cache(root_key)
      end
    end)
  end

  @expires_in_minute 24 * 60
  @leeway_minute_mean 60
  @leeway_minute_variance 10

  defp refresh_if_expiring(%MemberCache{updated_at: ua} = mc, root_key) do
    leeway_minutes = round(:rand.normal(@leeway_minute_mean, @leeway_minute_variance))
    if Time.now() < Time.shift_minutes(ua, @expires_in_minute - leeway_minutes) do
      {:ok, mc}
    else
      ensure_global_cache(root_key)
    end
  end

  defp ensure_global_cache(key) do
    R.m do
      token <- AdminToken.retrieve()
      users <- Users.list(token)
      data = %{list: sanitize(users)}
      upsert(%{data: %{"$set" => data}, data_on_insert: data}, MemberCache.id(), key)
    end
  end

  defp sanitize(users) do
    users
    |> Enum.reduce([], fn user, acc ->
      email = user["primaryEmail"]
      if acceptable?(email), do: [email | acc], else: acc
    end)
    |> Enum.reverse()
  end

  defp acceptable?(email) do
    not String.starts_with?(email, "admin") and
    not String.starts_with?(email, "acsmain.user1") and
    email =~ ~r/\A\w+\.\w+@access-company.com\Z/
  end
end
