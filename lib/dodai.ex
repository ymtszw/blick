defmodule Blick.Dodai do
  @local_group_id "g_HKNbCf7m"
  @dev_group_id   "g_hYCkmHdX"
  default_group_id =
    case SolomonLib.Env.compile_env() do
      :prod -> raise("Not production ready!")
      :dev -> @dev_group_id
      _ -> @local_group_id
    end
  use SolomonAcs.Dodai.GearModule, [
    app_id: "a_kkApL5Ll",
    default_group_id: default_group_id,
  ]

  def local_group_id(), do: @local_group_id
  def dev_group_id(), do: @dev_group_id

  def app_key(), do: "akey_sixX5ppp4RKTCoT"

  def root_key(), do: Blick.get_env("root_key")
end
