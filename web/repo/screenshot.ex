defmodule Blick.Repo.Screenshot do
  alias Blick.Model.Screenshot
  use Blick.Dodai.Repo.Filestore, [
    filestore_models: [Screenshot],
    read_permission: :anyone,
    write_permission: :anyone,
    max_versions: 3,
    client_config: %{recv_timeout: 30_000} # notify_upload_finish may take exceptionally long time
  ]
end
