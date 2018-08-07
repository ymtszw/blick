use Croma

defmodule Blick.Plug.Auth do
  use Antikythera.Controller
  alias Antikythera.IpAddress.V4

  @doc """
  Authenticate requests by their sender.

  - From intranet: OK
  - From public network:
      - Have `authorization` header:
          - Authenticate with worker_key
      - Prompt login (TODO)
  - G2g: Reject
  """
  def authenticate_by_sender(conn0, _opts) do
    authenticate_or_identify_sender(conn0, fn conn1 ->
      case sender_identity(conn1.request.sender) do
        :g2g ->
          Conn.json(conn1, 403, %{error: "g2g request is forbidden"})
        :intra ->
          conn1 |> Conn.assign(:from, :intra) |> Conn.assign(:key, Blick.Dodai.root_key())
        :public ->
          Conn.redirect(conn1, Blick.Router.public_login_path())
      end
    end)
  end

  defp authenticate_or_identify_sender(%Conn{request: req} = conn, fun) do
    # TODO: use cookie too, for XHR API usage
    case req.headers do
      %{"authorization" => api_key} ->
        authenticate_api_client(conn, api_key)
      _no_auth_header ->
        fun.(conn)
    end
  end

  defp authenticate_api_client(conn, api_key) do
    worker_key = Blick.get_env("worker_key")
    case Blick.decrypt_base64(api_key) do
      {:ok, ^worker_key} ->
        conn |> Conn.assign(:from, :worker) |> Conn.assign(:key, Blick.Dodai.root_key())
      _otherwise ->
        Conn.json(conn, 401, %{error: "Unauthorized"})
    end
  end

  defunp sender_identity(sender :: Antikythera.Request.Sender.t) :: :intra | :public | :g2g do
    {:web, ip_str} ->
      case V4.parse(ip_str) do
        {:ok, ip} ->
          intra_or_public(ip)
        {:error, _} ->
          :public
      end
    {:gear, _} ->
      :g2g
  end

  if Antikythera.Env.compiling_for_cloud?() do
    @intra_ranges AntikytheraAcs.IpAddress.Access.Tokyo.ranges() -- [V4.parse_range!("221.112.40.64/29")] # Removing visitor/artifact/proxy
    defp intra_or_public(ip) do
      if Enum.any?(@intra_ranges, &V4.range_include?(&1, ip)) do
        :intra
      else
        :public
      end
    end
  else
    # Local development and tests
    defp intra_or_public(_ip) do
      :intra
    end
  end

  @doc """
  Check if AdminToken is present.

  If not, redirect to /admin/authorize
  """
  def ensure_admin_authorization(conn, _opts) do
    if admin() do
      Conn.assign(conn, :authorized?, true)
    else
      Conn.redirect(conn, Blick.Router.authorize_path())
    end
  end

  def admin() do
    case Blick.Repo.AdminToken.retrieve() do
      {:ok, %Blick.Model.AdminToken{data: data}} -> data.owner
      {:error, _} -> nil
    end
  end

  # Helper

  def generate_api_key(worker_key, encryption_key) do
    worker_key |> Antikythera.Crypto.Aes.ctr128_encrypt(encryption_key) |> Base.encode64()
  end
end
