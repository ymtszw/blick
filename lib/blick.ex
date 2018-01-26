defmodule Blick do
  use SolomonLib.GearApplication
  alias SolomonLib.{ExecutorPool, Conn, Time}
  alias SolomonLib.Crypto.Aes

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

  # HACK: unofficial callback injection, performs bootstrap operation in local development
  if SolomonLib.Env.compiling_for_cloud?() or Mix.env() == :test do
    def start_phase(:after_start, _type, []), do: :ok
  else
    def start_phase(:after_start, _type, []) do
      {:ok, _id} = Blick.AsyncJob.MaterialRefresher.run_hourly()
      # Blick.AsyncJob.MaterialCollecter.run_hourly() # Collecter may not need to run after some sample materials are collected
      :ok
    end
  end

  # Convenient APIs

  def encrypt_base64!(plain_text) do
    if String.printable?(plain_text) do
      plain_text |> Aes.ctr128_encrypt(get_env("encryption_key")) |> Base.encode64()
    else
      raise("Only printable characters are supported.")
    end
  end

  def decrypt_base64(base64_text) do
    case Base.decode64(base64_text) do
      {:ok, encrypted_binary} -> decrypt_impl(encrypted_binary, get_env("encryption_key"))
      :error -> {:error, {:invalid_value, :base64_string}}
    end
  end

  defp decrypt_impl(encrypted_binary, encryption_key) do
    case Aes.ctr128_decrypt(encrypted_binary, encryption_key) do
      {:ok, string} ->
        if String.printable?(string) do
          {:ok, string}
        else
          # This indicates the encryption_key differs from the one used on encryption
          {:error, {:invalid_value, :aes_encrypted_string}}
        end
      {:error, _} = e -> e
    end
  end

  def log_elapsed(message, prev_time, start_time \\ nil) do
    now = Time.now()
    total = if start_time, do: " (#{Time.diff_milliseconds(now, start_time)}ms)", else: ""
    Blick.Logger.debug("#{message} #{Time.diff_milliseconds(now, prev_time)}ms#{total}")
    now
  end

  def with_logging_elapsed(message, fun) do
    prev_time = Time.now()
    res = fun.()
    log_elapsed(message, prev_time)
    res
  end
end
