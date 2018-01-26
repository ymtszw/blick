SolomonLib.Test.Config.init()
SolomonLib.Test.GearConfigHelper.set_config(%{
  "root_key" => "rkey_test",
  "google_client_id" => "google_client_id_test",
  "google_client_secret" => "google_client_secret_test",
  "encryption_key" => "TestEncryptionKey",
})
Blick.Mocks.inject([
  {Blick.Repo.AdminToken, StubAdminTokenRepo, exports_as_contract: true},
])

defmodule Req do
  use SolomonLib.Test.HttpClient
end

defmodule Socket do
  use SolomonLib.Test.WebsocketClient
end
