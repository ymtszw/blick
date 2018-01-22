use Croma

defmodule Blick.External.Google.Drive do
  @moduledoc """
  Binding for Google Drive API.
  """

  alias Blick.External.Google

  defmodule Files do
    @base_url "https://www.googleapis.com/drive/v3"

    defun get(id :: v[String.t], token :: Google.token_t) :: Google.res_t do
      Google.request(token, :get, @base_url <> "/files/#{id}", "", %{}, params: %{"fields" => "id,name,mimeType,createdTime,owners"})
    end

    defun batch_get(ids :: v[[String.t]], token :: Google.token_t) :: Google.res_t do
      requests = Enum.map(ids, fn id -> {:get, @base_url <> "/files/#{id}", "", %{}, params: %{"fields" => "id,name,mimeType,createdTime,owners"}} end)
      Google.batch(token, requests)
    end

    Croma.Result.define_bang_version_of(get: 2)
  end
end
