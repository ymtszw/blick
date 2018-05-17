use Croma

defmodule Blick.Model.AdminToken do
  alias Antikythera.Time

  @id "global_admin_token"
  def id(), do: @id

  use AntikytheraAcs.Dodai.Model.Datastore, [
    id_pattern: ~r/\A#{@id}\Z/, # There can be only one AdminToken
    data_fields: [
      access_token: Blick.SecretString,
      refresh_token: Blick.SecretString,
      expires_at: Antikythera.Time,
      owner: Antikythera.Email,
    ],
  ]

  defun expired?(%__MODULE__{data: %Data{expires_at: ea}}, now :: v[Time.t]) :: boolean do
    ea <= now
  end
end
