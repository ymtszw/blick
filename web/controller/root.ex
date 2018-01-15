use Croma

defmodule Blick.Controller.Root do
  use SolomonLib.Controller
  alias SolomonLib.IpAddress

  plug __MODULE__, :filter_by_sender_identity, [only: :index]

  # GET /login
  def public_login(conn) do
    json(conn, 403, %{"error" => "Access from public network is under development"})
  end

  # GET /*path
  def index(conn) do
    render(conn, 200, "root", [
      title: "Blick",
      path: conn.request.path_matches[:path],
    ])
  end

  # Plug

  def filter_by_sender_identity(conn, _opts) do
    case sender_identity(conn.request.sender) do
      :g2g -> json(conn, 403, %{"error" => "g2g request is forbidden"})
      :intra -> conn
      :public -> authenticate(conn)
    end
  end

  defunp sender_identity(sender :: SolomonLib.Request.Sender.t) :: :intra | :public | :g2g do
    {:web, ip_str} ->
      case IpAddress.V4.parse(ip_str) do
        {:ok, ip} ->
          intra_or_public(ip)
        {:error, _} ->
          # Suspicious
          :public
      end
    {:gear, _} ->
      :g2g
  end

  if SolomonLib.Env.compiling_for_cloud?() do
    defp intra_or_public(ip) do
      if Enum.any?(SolomonAcs.IpAddress.Access.ranges(), &IpAddress.V4.range_include?(&1, ip)) do
        :intra
      else
        :public
      end
    end
  else
    defp intra_or_public(_ip) do
      :intra
    end
  end

  defp authenticate(conn) do
    # NYI
    redirect(conn, Blick.Router.public_login_path())
  end
end
