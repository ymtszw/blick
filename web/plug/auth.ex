use Croma

defmodule Blick.Plug.Auth do
  use SolomonLib.Controller
  alias SolomonLib.IpAddress.V4

  @doc """
  Filter request by sender.

  - From intranet: OK
  - From public network: Prompt login (TODO)
  - G2g: Reject
  """
  def filter_by_sender_identity(conn, _opts) do
    case sender_identity(conn.request.sender) do
      :g2g -> json(conn, 403, %{"error" => "g2g request is forbidden"})
      :intra -> assign(conn, :from, :intra)
      :public -> conn |> assign(:from, :public) |> authenticate()
    end
  end

  defunp sender_identity(sender :: SolomonLib.Request.Sender.t) :: :intra | :public | :g2g do
    {:web, ip_str} ->
      case V4.parse(ip_str) do
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
    @intra_ranges SolomonAcs.IpAddress.Access.ranges() -- [V4.parse_range!("221.112.40.64/29")] # Removing visitor/artifact/proxy
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

  defp authenticate(conn) do
    # TODO currently always redirect to login path
    redirect(conn, Blick.Router.public_login_path())
  end

  @doc """
  Check if AdminToken is present.

  If not, redirect to /admin/authorize
  """
  def ensure_admin_authorization(conn, _opts) do
    if admin() do
      assign(conn, :authorized?, true)
    else
      redirect(conn, Blick.Router.authorize_path())
    end
  end

  def admin() do
    case Blick.Repo.AdminToken.retrieve() do
      {:ok, %Blick.Model.AdminToken{data: data}} -> data.owner
      {:error, _} -> nil
    end
  end
end
