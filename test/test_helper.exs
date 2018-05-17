Antikythera.Test.Config.init()
Antikythera.Test.GearConfigHelper.set_config(%{
  "root_key" => "rkey_test",
  "google_client_id" => "google_client_id_test",
  "google_client_secret" => "google_client_secret_test",
  "worker_key" => "TestWorkerKey",
  "encryption_key" => "TestEncryptionKey",
})
Blick.Mocks.inject([
  {Blick.Repo.AdminToken, StubAdminTokenRepo, exports_as_contract: true},
  {AntikytheraAcs.Dodai.Repo.Datastore, StubDatastore, exports_as_contract: true},
])

defmodule Req do
  use Antikythera.Test.HttpClient
end

defmodule Socket do
  use Antikythera.Test.WebsocketClient
end
