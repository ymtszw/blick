defmodule Blick.Dodai do
  default_group_id = if SolomonLib.Env.compiling_for_cloud?(), do: "g_hYCkmHdX", else: "g_HKNbCf7m"
  use SolomonAcs.Dodai.GearModule, [
    app_id: "a_kkApL5Ll",
    default_group_id: default_group_id,
  ]

  def app_key(), do: "akey_sixX5ppp4RKTCoT"

  def root_key(), do: Blick.get_env("root_key")
end
