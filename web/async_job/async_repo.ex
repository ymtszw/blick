defmodule Blick.AsyncJob.AsyncRepo.Material do
  use SolomonLib.AsyncJob
  alias Blick.Repo

  @impl true
  def run(%{repo: Repo.Material, update_action: update_action, _id: id, key: key}, _metadata, _context) do
    {:ok, _} = Repo.Material.update(update_action, id, key)
  end

  def update(update_action, id, key) do
    payload = %{repo: Repo.Material, update_action: update_action, _id: id, key: key}
    register(payload, {:gear, :blick}, id: payload_to_id(payload))
  end

  defp payload_to_id(payload) do
    :crypto.hash(:md5, inspect(payload)) |> Base.encode32(padding: false)
  end
end
