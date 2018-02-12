use Croma

defmodule Blick.Controller.Screenshot do
  alias Croma.Result, as: R
  use SolomonLib.Controller

  plug __MODULE__, :authenticate_worker, []

  @doc """
  Returns list of materials which needs screenshot to be attached.
  """
  def list(_conn) do
    # TODO:
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
