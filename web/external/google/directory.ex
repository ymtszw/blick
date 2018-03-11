use Croma

defmodule Blick.External.Google.Directory do
  @moduledoc """
  Binding for Google Directory API.

  It only fetches public resourecs (available to non-admin).

  You may reach per-user request limit easily. Better cache results.
  """

  alias Blick.External.Google

  defmodule Users do
    @base_url "https://www.googleapis.com/admin/directory/v1"
    @max_results 500

    defun list(query :: v[nil | String.t] \\ nil, token :: Google.token_t) :: Google.res_t do
      list_impl(query, nil, token, [])
    end

    defp list_impl(query, next_page_token, token, acc) do
      case list_up_to_500(query, next_page_token, token) do
        {:ok, %{"nextPageToken" => npt, "users" => users}} when is_binary(npt) ->
          list_impl(query, npt, token, Enum.reverse(users) ++ acc)
        {:ok, %{"users" => users}} ->
          {:ok, Enum.reverse(users) ++ acc}
        {:error, _} = e ->
          e
      end
    end

    defp list_up_to_500(query, next_page_token, token) do
      params = without_nil(%{
        "domain" => "access-company.com",
        "viewType" => "domain_public",
        "orderBy" => "email",
        "sortOrder" => "DESCENDING",
        "maxResults" => @max_results,
        "pageToken" => next_page_token,
        "query" => query,
      })
      Google.request(token, :get, @base_url <> "/users", "", %{}, params: params)
    end

    defp without_nil(map) do
      for {k, v} when not is_nil(v) <- map, into: %{}, do: {k, v}
    end
  end
end
