defmodule Blick.AsyncJob.AsyncRepo do
  use Antikythera.AsyncJob
  alias Blick.Repo

  @impl true
  def run(%{mod: mod, fun: fun, args: args}, _metadata, _context) do
    {:ok, _} = apply(mod, fun, args)
  end

  # Convenient APIs

  def update(repo, update_action, id, key) do
    register_once(%{mod: Module.safe_concat(Repo, repo), fun: :update, args: [update_action, id, key]})
  end

  def notify_upload_finish(file_repo, id, key) do
    register_once(%{mod: Module.safe_concat(Repo, file_repo), fun: :notify_upload_finish, args: [id, key]})
  end

  # Internals

  defp register_once(payload) do
    register(payload, {:gear, :blick}, id: payload_to_id(payload))
  end

  defp payload_to_id(payload) do
    :crypto.hash(:md5, inspect(payload)) |> Base.encode32(padding: false)
  end
end
