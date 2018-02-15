defmodule Blick.AsyncJob.ScreenshotSetter do
  use SolomonLib.AsyncJob
  alias Blick.Repo
  alias Blick.Model.Screenshot

  @impl true
  def run(%{_id: id, key: key}, _metadata, _context) do
    {:ok, %Screenshot{public_url: thumbnail_url}} = Repo.Screenshot.notify_upload_finish(id, key)
    {:ok, _} = Repo.Material.update(%{data: %{"$set" => %{thumbnail_url: thumbnail_url}}}, id, key)
  end

  def exec(id, key) do
    register(%{_id: id, key: key}, {:gear, :blick}, id: id)
  end
end
