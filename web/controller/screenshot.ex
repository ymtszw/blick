use Croma

defmodule Blick.Controller.Screenshot do
  use SolomonLib.Controller
  import Blick.Dodai, only: [root_key: 0]
  alias Blick.Repo
  alias Blick.AsyncJob.ScreenshotSetter
  alias Blick.Model.Screenshot

  plug Blick.Plug.Auth, :authenticate_by_sender, []

  @doc """
  Returns list of materials which needs first screenshot to be attached.
  """
  def list(%Conn{request: req} = conn) do
    query =
      if req.query_params["refresh"] == "true" do
        Repo.Material.non_google()
      else
        Repo.Material.non_google_without_ss()
      end
    case Repo.Material.retrieve_list(query, root_key()) do
      {:ok, materials} ->
        json(conn, 200, %{materials: materials})
      {:error, %_error{status_code: code, body: body}} ->
        json(conn, code, body)
    end
  end

  @doc """
  Initiates new screenshot upload. Takes Material's _id and screenshot byte size.
  """
  def request_upload_start(%Conn{request: req} = conn) do
    case upsert(req.path_matches.id, req.body["size"], root_key()) do
      {:ok, %Screenshot{} = ss} ->
        json(conn, 200, ss)
      {:error, %_error{status_code: code, body: body}} ->
        json(conn, code, body)
    end
  end

  defp upsert(id, size, root_key) do
    case Repo.Screenshot.update(%{}, id, root_key) do
      {:ok, %Screenshot{}} = ok ->
        ok
      {:error, %Dodai.ResourceNotFound{}} ->
        # Use same _id for Material data entity and Screenshot file entity
        insert_action = %{_id: id, filename: id, content_type: "image/png", size: size, public: true}
        Repo.Screenshot.insert(insert_action, root_key)
    end
  end

  def notify_upload_finish(%Conn{request: req} = conn) do
    ScreenshotSetter.exec(req.path_matches.id, root_key())
    put_status(conn, 204)
  end
end
