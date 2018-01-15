defmodule Blick do
  use SolomonLib.GearApplication
  alias SolomonLib.{ExecutorPool, Conn}

  @spec children :: [Supervisor.Spec.spec]
  def children() do
    [
      # gear-specific workers/supervisors
    ]
  end

  @spec executor_pool_for_web_request(Conn.t) :: ExecutorPool.Id.t
  def executor_pool_for_web_request(_conn) do
    # specify executor pool to use; change the following line if your gear serves to multiple tenants
    {:gear, :blick}
  end
end
