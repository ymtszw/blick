use Croma

defmodule Blick.External.Google.People do
  @moduledoc """
  Binding for Google People API.
  """

  alias Blick.External.Google

  @base_url "https://people.googleapis.com/v1"

  defun me(token :: Google.token_t) :: Google.res_t do
    params = %{"personFields" => "emailAddresses,memberships,organizations"}
    Google.request(token, :get, @base_url <> "/people/me", "", %{}, params: params)
  end

  Croma.Result.define_bang_version_of(me: 1)
end
