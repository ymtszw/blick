use Croma

defmodule Blick.External.Google.Drive do
  @moduledoc """
  Binding for Google Drive API.

  You may reach per-user request limit.
  """

  alias Croma.Result, as: R
  alias Blick.External.Google

  defmodule Files do
    @base_url "https://www.googleapis.com/drive/v3"
    @fields "id,name,mimeType,createdTime,owners,thumbnailLink"

    defun get(id :: v[String.t], token :: Google.token_t) :: Google.res_t do
      Google.request(token, :get, @base_url <> "/files/#{id}", "", %{}, params: %{"fields" => @fields})
    end

    @doc """
    Batch get Google Drive Files.
    """
    defun batch_get(ids :: v[[String.t]], token :: Google.token_t) :: Google.res_t do
      Blick.with_logging_elapsed("#{length(ids)} files retrieved in:", fn ->
        ids
        |> Enum.chunk_every(100) # Batch request for Google Drive API is limited to 100 requests per batch
        |> Enum.map(&mini_batch_get(&1, token))
        |> R.sequence()
        |> R.map(&List.flatten/1)
      end)
    end

    defp mini_batch_get(ids_upto_100, token) do
      requests = Enum.map(ids_upto_100, fn id -> {:get, @base_url <> "/files/#{id}", "", %{}, params: %{"fields" => @fields}} end)
      Google.batch(token, requests)
    end

    Croma.Result.define_bang_version_of(get: 2)
  end
end
