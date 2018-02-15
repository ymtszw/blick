use Croma

defmodule Blick.External.Google.Drive do
  @moduledoc """
  Binding for Google Drive API.

  You may reach per-user request limit.
  """

  alias Blick.External.Google

  defmodule Files do
    @base_url "https://www.googleapis.com/drive/v3"
    @fields "id,name,mimeType,createdTime,owners,thumbnailLink"

    defun get(id :: v[String.t], token :: Google.token_t) :: Google.res_t do
      Google.request(token, :get, @base_url <> "/files/#{id}", "", %{}, params: %{"fields" => @fields})
    end

    @doc """
    Batch get Google Drive Files.

    Batch request for Google Drive API is limited to 100 requests per batch,
    though seemingly they have stricter rate limit at Query-per-second resolution.
    So we have to split loads into more smaller chunks
    and manually introduce client side throttling (i.e. retry with backoffs).

    Results will be sorted by `id`.
    """
    defun batch_get(ids :: v[[String.t]], token :: Google.token_t) :: Google.res_t do
      Blick.with_logging_elapsed("#{length(ids)} files retrieved in:", fn ->
        ids
        |> Enum.chunk_every(10)
        |> batch_get_with_retry(token, [], 0)
      end)
    end

    @backoff_base 2

    # Minimum of 1 second
    defp backoff(attempts_with_failure), do: 1_000 * round(:math.pow(@backoff_base, attempts_with_failure))

    defp batch_get_with_retry([], _token, acc, _attempts_with_failure) do
      {:ok, Enum.sort_by(acc, fn {_status, %{"id" => id}} -> id end)}
    end
    defp batch_get_with_retry([chunk | chunks], token, acc, attempts_with_failure) do
      requests = Enum.map(chunk, fn id -> {:get, @base_url <> "/files/#{id}", "", %{}, params: %{"fields" => @fields}} end)
      case Google.batch(token, requests) do
        {:ok, results} ->
          {new_chunks, new_acc, new_attempts} =
            examine_batch_results(results, chunk, chunks, acc, attempts_with_failure)
          :timer.sleep(backoff(attempts_with_failure))
          batch_get_with_retry(new_chunks, token, new_acc, new_attempts)
        {:error, _} = e ->
          e
      end
    end

    defp examine_batch_results(results, chunk, chunks, acc, attempts_with_failure) do
      case Enum.split_with(results, fn {status, _} -> status == 200 end) do
        {successes, []} ->
          {chunks, successes ++ acc, 0}
        {successes, _failures} ->
          succeeded_ids = Enum.map(successes, fn {_status, %{"id" => id}} -> id end)
          failed_ids = chunk -- succeeded_ids
          Blick.Logger.debug("Failed to retrieve #{inspect(failed_ids)}. Retrying them.")
          {[failed_ids | chunks], successes ++ acc, attempts_with_failure + 1}
      end
    end

    Croma.Result.define_bang_version_of(get: 2)
  end
end
