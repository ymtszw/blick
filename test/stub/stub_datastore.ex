use Croma

defmodule StubDatastore do
  alias Croma.Result, as: R
  alias Dodai.{Client, GroupId, CollectionName}
  alias AntikytheraAcs.Dodai.Repo
  alias AntikytheraAcs.Dodai.Repo.Datastore, as: RD

  defun retrieve_list(_list_action     :: RD.list_action_t,
                      _key             :: String.t,
                      group_id         :: v[GroupId.t],
                      %Client{app_id: app_id},
                      collection_name  :: v[CollectionName.t],
                      shared?          :: v[boolean],
                      datastore_models :: v[[module]]) :: R.t([struct]) do
    ensure_agent_started()
    |> Agent.get(fn in_memory_datastore ->
      in_memory_datastore
      |> Map.get(collection(app_id, group_id, shared?, collection_name), [])
      |> Enum.take(1_000)
      |> dodai_response(:retrieve_list, shared?)
    end)
    |> Repo.handle_multi_entity_api_response([datastore_models])
  end

  defp dodai_response(contents, :retrieve_list, true) do
    %Dodai.RetrieveSharedDataEntityListSuccess{status_code: 200, body: contents}
  end
  defp dodai_response(contents, :retrieve_list, false) do
    %Dodai.RetrieveDedicatedDataEntityListSuccess{status_code: 200, body: contents}
  end

  defp collection(app_id, group_id, shared?, collection_name) do
    if shared? do
      {app_id, group_id, "shared-#{collection_name}"}
    else
      {app_id, group_id, "#{app_id}-#{collection_name}"}
    end
  end

  defunp ensure_agent_started() :: pid do
    case Agent.start(fn -> %{} end, [name: __MODULE__]) do
      {:ok, pid}                        -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end
end
