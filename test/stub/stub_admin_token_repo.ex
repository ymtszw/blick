defmodule StubAdminTokenRepo do
  @moduledoc """
  Stub of `Blick.Repo.AdminToken`.
  """

  alias Antikythera.Time
  alias Blick.Model.AdminToken

  @stub_admin_token %AdminToken{
    _id: AdminToken.id(),
    owner: "_root",
    sections: [],
    created_at: Time.now(),
    updated_at: Time.now(),
    version: 0,
    data:
      %AdminToken.Data{
        access_token: %Blick.SecretString{value: "stub_access_token"},
        expires_at: Time.now() |> Time.shift_hours(1),
        owner: "blick-admin-gr@access-company.com",
        refresh_token: %Blick.SecretString{value: "stub_refresh_token"},
      },
    }

  def retrieve() do
    {:ok, @stub_admin_token}
  end
end
