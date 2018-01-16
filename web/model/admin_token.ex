use Croma

defmodule Blick.Model.AdminToken do
  alias SolomonLib.Time

  @id "global_admin_token"
  def id(), do: @id

  use SolomonAcs.Dodai.Model.Datastore, [
    id_pattern: ~r/\A#{@id}\Z/, # There can be only one AdminToken
    data_fields: [
      access_token: Blick.SecretString,
      refresh_token: Blick.SecretString,
      expires_at: SolomonLib.Time,
    ],
  ]

  defun expired?(%__MODULE__{data: %Data{expires_at: ea}}, now :: v[Time.t]) :: boolean do
    ea <= now
  end
end
