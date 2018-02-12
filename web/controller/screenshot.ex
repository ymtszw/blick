use Croma

defmodule Blick.Controller.Screenshot do
  alias Croma.Result, as: R
  use SolomonLib.Controller
  import Blick.Dodai, only: [root_key: 0]
  alias Blick.Repo

  plug __MODULE__, :authenticate_worker, []

  @doc """
  Returns list of materials which needs first screenshot to be attached.
  """
  def list_new(conn) do
    case Repo.Material.retrieve_list(Repo.Material.non_google_without_ss(), root_key()) do
      {:ok, materials} ->
        json(conn, 200, %{materials: materials})
      {:error, %_error{status_code: code, body: body}} ->
        json(conn, code, body)
    end
  end

  def create(_conn) do
    # TODO:
  end

  def notify_upload_finish(_conn) do
    # TODO:
  end

  # Plug

  def authenticate_worker(%Conn{request: req} = conn, _opts) do
    req.headers
    |> Map.get("authorization", "")
    |> Blick.decrypt_base64()
    |> R.map(fn key -> key == Blick.get_env("worker_key") end)
    |> case do
      {:ok, true} -> conn
      _otherwise -> json(conn, 401, %{error: "Unauthorized"})
    end
  end

  # Helper

  def generate_api_key(worker_key, encryption_key) do
    worker_key |> SolomonLib.Crypto.Aes.ctr128_encrypt(encryption_key) |> Base.encode64()
  end
end
