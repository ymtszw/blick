# Set context ID for gear_log
Process.put(:solomon_context_id, SolomonCore.Context.make_context_id(SolomonLib.Time.now()))
# Blick.AsyncJob.MaterialRefresher.run_hourly()
Blick.Logger.debug("AsyncJobs: #{inspect(SolomonLib.AsyncJob.list({:gear, :blick}))}")
