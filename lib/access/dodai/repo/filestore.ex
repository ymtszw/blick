use Croma

defmodule Blick.Dodai.Repo.Filestore do
  @moduledoc """
  Generator of easy-to-use wrapper functions of
  [Dodai Filestore APIs](https://github.com/access-company/Dodai-doc/blob/master/filestore_api.md).

  Use `SolomonAcs.Dodai.Model.Filestore` in order to generate struct modules
  representing model object in your gear.

  ## Usage

      defmodule YourGear.Repo.SomeModel do
        use #{inspect(__MODULE__)}, [
          filestore_models:     [YourGear.Model.SomeModel],
          client_config:        %{recv_timeout: 10_000},
          shared?:              false,
          read_permission:      :section_or_owner,
          write_permission:     :section_or_owner,
          volume_usage_counted: true,
          max_versions:         1,
        ]
      end

      YourGear.Repo.SomeModel.create_collection()
      # => {:ok, %Dodai.Model.CollectionSetting{type: :file, name: "SomeModel", ...}}

      insert_action = %{filename: "myimage.png", content_type: "image/png", size: 100, public: false}
      YourGear.Repo.SomeModel.insert(insert_action, "userkey0123456789abc", "g_01234567")
      # => {:ok, %YourGear.Model.SomeModel{_id: "someentityid0123", data: %YourGear.Model.SomeModel.Data{...}, upload_url: "https://...", ...}}

      YourGear.Repo.SomeModel.retrieve("someentityid0123", "userkey0123456789abc", "g_01234567")
      # => {:ok, %YourGear.Model.SomeModel{_id: "someentityid0123", data: %YourGear.Model.SomeModel.Data{...}, upload_url: "https://...", ...}}

  As you can see, basic CRUD functions will be generated under `YourGear.Repo.SomeModel`. Including:

  - `insert/3` (implying "request initial uploadUrl")
  - `update/4` (implying "request new uploadUrl")
  - `delete/3` (implying physical delete, i.e. `allVersions=true`)
  - `retrieve/3` (implying "request downloadUrl, if authorized")
  - `retrieve_list/3`
  - `count/3`

  In addition to them, `create_collection` and `drop_collection` functions will be generated too,
  wrapping [Dodai CollectionSetting APIs](https://github.com/access-company/Dodai-doc/blob/master/collection_setting_api.md).

  Module name itself will be used as File collection name. For instance, "SomeModel" from `YourGear.Repo.SomeModel`.
  Note that you CANNOT nest repo module names like `YourGear.Repo.SomeScope.SomeModel`.

  Also, it generates the following:

  - `notify_upload_finish/3`
  - `freeze/2`
  - `drop_file_version/3`

  ## Options

  - `:filestore_models` - List of struct modules that represent your models. Required. Must not be empty.
      - See `SolomonAcs.Dodai.Repo` about handling of multiple models.
  - `:client_config` - `Dodai.Client.config_t`. Optional. If specified, it will be used on every request from the repo.
      - Merged with config specified by `:default_client_config` when using `SolomonAcs.Dodai.GearModule`.
        For duplicated fields in config, ones from repo module will prevail.
  - `:shared?` - `boolean`. Optional. Defaults to `false`. Controls whether the backend Dodai collection for this repo is a shared collection or a dedicated one.
  - `:read_permission` and `:write_permission` - `Dodai.CustomCollectionPermissionLevel.t`. Optional. Both default to `:section_or_owner`.
  - `:volume_usage_counted` - `boolean`. Optional. Defaults to `true`. Controls whether total volume usage of a file collection is counted for the size limitation or not.
  - `:max_versions` - `non_neg_integer`, must be within 1 to 5. Optional. Defaults to 1. Maximum versions to be maintained per file.
  """

  alias Croma.Result, as: R
  alias Dodai.{Client, GroupId, GenericEntityId, CollectionName, CustomCollectionPermissionLevel, MaxVersions}
  # alias SolomonLib.CodeUtil # XXX: to workaround compile error on Code.get_docs/2 without .beam file
  alias SolomonAcs.Dodai.Repo
  alias __MODULE__, as: RF

  @typedoc """
  Map version of `Dodai.CreateDedicatedFileEntityRequestBody`
  or `Dodai.CreateSharedFileEntityRequestBody`.

  If `id_pattern` is specified for the model module, `:_id` is required.
  In File Entities, `:data` is not mandatory but will be validated if used.
  """
  @type insert_action_t :: %{
    optional(:_id)               => GenericEntityId.t,
    optional(:owner)             => Dodai.Owner.t,
    optional(:sections)          => Dodai.Sections.t,
    optional(:data)              => map, # Will be validated with submodules of user defined Model modules
    optional(:label)             => String.t,
    required(:filename)          => String.t,
    required(:content_type)      => String.t,
    required(:size)              => non_neg_integer,
    optional(:upload_using_form) => map,
    optional(:public)            => boolean,
  }

  @doc """
  Inserts a new Dodai file entity with initial `:upload_url`.

  Fields of `insert_action` are validated by corresponding type modules.
  """
  defun insert(insert_action    :: insert_action_t,
               key              :: v[String.t],
               group_id         :: v[GroupId.t],
               client           :: Client.t,
               collection_name  :: v[CollectionName.t],
               shared?          :: v[boolean],
               filestore_models :: v[[module]]) :: R.t(struct) do
    R.m do
      {matched_model, i_a} <- validate_on_insert_by_filestore_models(insert_action, filestore_models)
      {body_mod, req_mod}  =  insert_request_modules(shared?)
      body                 <- body_mod.new(i_a)
      req                  =  req_mod.new(group_id, collection_name, key, body)
      Client.send(client, req) |> Repo.handle_single_entity_api_response([matched_model])
    end
  end

  defpt validate_on_insert_by_filestore_models(map, [filestore_model]) do
    filestore_model.validate_on_insert(map)
  end
  defpt validate_on_insert_by_filestore_models(map, [filestore_model | filestore_models]) do
    filestore_model.validate_on_insert(map)
    |> R.or_else(validate_on_insert_by_filestore_models(map, filestore_models))
  end

  defp insert_request_modules(true ), do: {Dodai.CreateSharedFileEntityRequestBody, Dodai.CreateSharedFileEntityRequest}
  defp insert_request_modules(false), do: {Dodai.CreateDedicatedFileEntityRequestBody, Dodai.CreateDedicatedFileEntityRequest}

  @typedoc """
  Map version of `Dodai.UpdateDedicatedFileEntityRequestBody`
  or `Dodai.UpdateSharedFileEntityRequestBody`.
  """
  @type update_action_t :: %{
    optional(:owner)             => Dodai.Owner.t,
    optional(:version)           => non_neg_integer,
    optional(:data)              => map,
    optional(:filename)          => String.t,
    optional(:content_type)      => String.t,
    optional(:size)              => non_neg_integer,
    optional(:upload_using_form) => map,
    optional(:public)            => boolean,
  }

  @doc """
  Updates a Dodai file entity, acquiring new `:upload_url`.

  Even if `update_action` is an empty map (`%{}`), this operation itself may result in success.
  When you upload new file via new `:upload_url`, you indirectly "update" the file entity.

  Due to complexity of MongoDB update operators, `:data` field of `update_action` will NOT be validated.
  """
  defun update(update_action    :: RF.update_action_t,
               id               :: v[GenericEntityId.t],
               key              :: v[String.t],
               group_id         :: v[GroupId.t],
               client           :: Client.t,
               collection_name  :: v[CollectionName.t],
               shared?          :: v[boolean],
               filestore_models :: v[[module]]) :: R.t(struct) do
    {body_mod, req_mod} = update_request_modules(shared?)
    R.bind(body_mod.new(update_action), fn body ->
      req = req_mod.new(group_id, collection_name, id, key, body)
      Client.send(client, req) |> Repo.handle_single_entity_api_response(filestore_models)
    end)
  end

  defp update_request_modules(true ), do: {Dodai.UpdateSharedFileEntityRequestBody, Dodai.UpdateSharedFileEntityRequest}
  defp update_request_modules(false), do: {Dodai.UpdateDedicatedFileEntityRequestBody, Dodai.UpdateDedicatedFileEntityRequest}

  @doc """
  Signals Dodai upon completion of file uploading for a Dodai file entity.

  Dodai will fetch file information from cloud file storage,
  then update `:file_versions` field of the entity,
  and finally return an updated file entity as a response.

  This can sometimes take longer time compared to other operations
  due to latencies of cloud file storage API.
  If you need to avoid unpredicted crash due to timeout,
  you can execute this part in asynchronous manner, using `SolomonLib.AsyncJob`.
  """
  defun notify_upload_finish(id               :: v[GenericEntityId.t],
                             key              :: v[String.t],
                             group_id         :: v[GroupId.t],
                             client           :: Client.t,
                             collection_name  :: v[CollectionName.t],
                             shared?          :: v[boolean],
                             filestore_models :: v[[module]]) :: R.t(struct) do
    Client.send(client, notify_request_module(shared?).new(group_id, collection_name, id, key))
    |> Repo.handle_single_entity_api_response(filestore_models)
  end

  defp notify_request_module(true ), do: Dodai.NotifySharedFileUploadFinishedRequest
  defp notify_request_module(false), do: Dodai.NotifyDedicatedFileUploadFinishedRequest

  @doc """
  Deletes a Dodai file entity AND all versions of file attached to it.

  This implies `allVersions=true` query parameter. This operation cannot be undone.

  - If you just want to make files attached to the entity undownloadable, use `freeze` instead.
  - If you want to delete a specific version of file attached to the entity, use `drop_file_version` instead.
  """
  defun delete(id              :: v[GenericEntityId.t],
               version         :: v[nil | non_neg_integer],
               key             :: v[String.t],
               group_id        :: v[GroupId.t],
               client          :: Client.t,
               collection_name :: v[CollectionName.t],
               shared?         :: v[boolean]) :: R.t(:no_content) do
    {query_mod, req_mod} = delete_request_modules(shared?)
    R.bind(query_mod.new(%{allVersions: true, version: version}), fn query ->
      req = req_mod.new(group_id, collection_name, id, key, query)
      Client.send(client, req) |> Repo.handle_no_content_api_response()
    end)
  end

  defp delete_request_modules(true ), do: {Dodai.DeleteSharedFileEntityRequestQuery, Dodai.DeleteSharedFileEntityRequest}
  defp delete_request_modules(false), do: {Dodai.DeleteDedicatedFileEntityRequestQuery, Dodai.DeleteDedicatedFileEntityRequest}

  @doc """
  Makes files attached to a Dodai file entity undownloadable.

  The entity itself (and versions of files attached to it,
  as long as the `maxVersions` collection setting allows) will be kept.
  A "delete marker" will be added to `:file_versions` list in the entity.
  `:download_url` (and `:public_url` if public) will not be visible in the entity
  when it is retrieved after freezing.

  Note that if the entity is public, already generated (retrieved) `:public_url`
  will NOT become invalid with this operation,
  since they are basically permanent URL for a file.

  - If you want to "un-freeze" the entity, use `drop_file_version` with `version_id` of the delete marker.
  - If you want to entirely delete the entity and all versions of files attached to it, use `delete` instead.
  """
  defun freeze(id              :: v[GenericEntityId.t],
               key             :: v[String.t],
               group_id        :: v[GroupId.t],
               client          :: Client.t,
               collection_name :: v[CollectionName.t],
               shared?         :: v[boolean]) :: R.t(:no_content) do
    {query_mod, req_mod} = delete_request_modules(shared?)
    R.bind(query_mod.new(%{}), fn query ->
      req = req_mod.new(group_id, collection_name, id, key, query)
      Client.send(client, req) |> Repo.handle_no_content_api_response()
    end)
  end

  @doc """
  Deletes a version of file attached to a Dodai file entity.

  If the specified `version_id` is of a "delete marker",
  it means "un-freezing" the entity, making files attached to it downloadable again.

  This operation cannot be undone.
  """
  defun drop_file_version(id              :: v[GenericEntityId.t],
                          version_id      :: v[String.t],
                          key             :: v[String.t],
                          group_id        :: v[GroupId.t],
                          client          :: Client.t,
                          collection_name :: v[CollectionName.t],
                          shared?         :: v[boolean]) :: R.t(:no_content) do
    Client.send(client, drop_file_version_request_module(shared?).new(group_id, collection_name, id, version_id, key))
    |> Repo.handle_no_content_api_response()
  end

  defp drop_file_version_request_module(true ), do: Dodai.DeleteSharedFileEntityWithVersionRequest
  defp drop_file_version_request_module(false), do: Dodai.DeleteDedicatedFileEntityWithVersionRequest


  @doc """
  Retrieves a Dodai file entity.
  """
  defun retrieve(id               :: v[GenericEntityId.t],
                 key              :: v[String.t],
                 group_id         :: v[GroupId.t],
                 client           :: Client.t,
                 collection_name  :: v[CollectionName.t],
                 shared?          :: v[boolean],
                 filestore_models :: v[[module]]) :: R.t(struct) do
    Client.send(client, retrieve_request_module(shared?).new(group_id, collection_name, id, key))
    |> Repo.handle_single_entity_api_response(filestore_models)
  end

  defp retrieve_request_module(true ), do: Dodai.RetrieveSharedFileEntityRequest
  defp retrieve_request_module(false), do: Dodai.RetrieveDedicatedFileEntityRequest

  @typedoc """
  Map version of `Dodai.RetrieveDedicatedFileEntityListRequestQuery`
  or `Dodai.RetrieveSharedFileEntityListRequestQuery`.
  """
  @type list_action_t :: %{
    optional(:query) => Dodai.Query.t,
    optional(:sort)  => Dodai.Sort.t,
    optional(:limit) => pos_integer,
    optional(:skip)  => non_neg_integer,
  }

  @doc """
  Retrieves Dodai file entities.

  Note that they do not include `:download_url`s.
  If you want to download a version of file attached to a non-public file entity,
  use `retrieve` instead.

  Due to complexity of MongoDB query operators, `:query` field of `list_action` will NOT be validated.
  """
  defun retrieve_list(list_action      :: RF.list_action_t,
                      key              :: v[String.t],
                      group_id         :: v[GroupId.t],
                      client           :: Client.t,
                      collection_name  :: v[CollectionName.t],
                      shared?          :: v[boolean],
                      filestore_models :: v[[module]]) :: R.t([struct]) do
    {query_mod, req_mod} = retrieve_list_request_modules(shared?)
    R.bind(query_mod.new(list_action), fn query ->
      req = req_mod.new(group_id, collection_name, key, query)
      Client.send(client, req) |> Repo.handle_multi_entity_api_response(filestore_models)
    end)
  end

  defp retrieve_list_request_modules(true ), do: {Dodai.RetrieveSharedFileEntityListRequestQuery, Dodai.RetrieveSharedFileEntityListRequest}
  defp retrieve_list_request_modules(false), do: {Dodai.RetrieveDedicatedFileEntityListRequestQuery, Dodai.RetrieveDedicatedFileEntityListRequest}

  @doc """
  Counts number of Dodai file entities.

  Due to complexity of MongoDB query operators, `query` will NOT be validated.
  """
  defun count(query           :: v[nil | Dodai.Query.t],
              key             :: v[String.t],
              group_id        :: v[GroupId.t],
              client          :: Client.t,
              collection_name :: v[CollectionName.t],
              shared?         :: v[boolean]) :: R.t(non_neg_integer) do
    {query_mod, req_mod} = count_request_modules(shared?)
    R.bind(query_mod.new(%{query: query}), fn query ->
      req = req_mod.new(group_id, collection_name, key, query)
      Client.send(client, req) |> Repo.handle_count_api_response()
    end)
  end

  defp count_request_modules(true ), do: {Dodai.CountSharedFileEntitiesRequestQuery, Dodai.CountSharedFileEntitiesRequest}
  defp count_request_modules(false), do: {Dodai.CountDedicatedFileEntitiesRequestQuery, Dodai.CountDedicatedFileEntitiesRequest}

  # CollectionSetting APIs

  @doc """
  Creates a Dodai shared file collection setting.
  """
  defun create_shared_collection(read_permission      :: v[CustomCollectionPermissionLevel.t],
                                 write_permission     :: v[CustomCollectionPermissionLevel.t],
                                 volume_usage_counted :: v[boolean],
                                 max_versions         :: v[MaxVersions.t],
                                 root_key             :: v[String.t],
                                 group_id             :: v[GroupId.t],
                                 client               :: Client.t,
                                 collection_name      :: v[CollectionName.t]) :: R.t(Dodai.Model.CollectionSetting.t) do
    create_collection_impl(read_permission, write_permission, volume_usage_counted, max_versions, client, collection_name, Dodai.CreateSharedCollectionRequestBody, fn body ->
      Dodai.CreateSharedCollectionRequest.new(group_id, root_key, body)
    end)
  end

  @doc """
  Creates a Dodai dedicated file collection setting.
  """
  defun create_dedicated_collection(read_permission      :: v[CustomCollectionPermissionLevel.t],
                                    write_permission     :: v[CustomCollectionPermissionLevel.t],
                                    volume_usage_counted :: v[boolean],
                                    max_versions         :: v[MaxVersions.t],
                                    root_key             :: v[String.t],
                                    client               :: Client.t,
                                    collection_name      :: v[CollectionName.t]) :: R.t(Dodai.Model.CollectionSetting.t) do
    create_collection_impl(read_permission, write_permission, volume_usage_counted, max_versions, client, collection_name, Dodai.CreateDedicatedCollectionRequestBody, fn body ->
      Dodai.CreateDedicatedCollectionRequest.new(root_key, body)
    end)
  end

  defp create_collection_impl(read_permission, write_permission, volume_usage_counted, max_versions, client, collection_name, body_mod, req_builder_fun) do
    body_mod.new(%{
      type:               :file,
      name:               collection_name,
      readPermission:     read_permission,
      writePermission:    write_permission,
      volumeUsageCounted: volume_usage_counted,
      max_versions:       max_versions,
    })
    |> R.bind(fn body ->
      req = req_builder_fun.(body)
      Client.send(client, req) |> Repo.handle_single_entity_api_response([Dodai.Model.CollectionSetting])
    end)
  end

  @doc """
  Drops a Dodai shared file collection setting.

  Any stored data in the collection and all versions of attached files will be deleted.
  """
  defun drop_shared_collection(root_key        :: v[String.t],
                               group_id        :: v[GroupId.t],
                               client          :: Client.t,
                               collection_name :: v[CollectionName.t]) :: R.t(:no_content) do
    Client.send(client, Dodai.DeleteSharedCollectionRequest.new(group_id, collection_name, root_key))
    |> Repo.handle_no_content_api_response()
  end

  @doc """
  Drops a Dodai dedicated file collection setting.

  Any stored data in collections and all versions of attached files FOR ALL ASSOCIATED GROUPS will be deleted.
  """
  defun drop_dedicated_collection(root_key        :: v[String.t],
                                  client          :: Client.t,
                                  collection_name :: v[CollectionName.t]) :: R.t(:no_content) do
    Client.send(client, Dodai.DeleteDedicatedCollectionRequest.new(collection_name, root_key))
    |> Repo.handle_no_content_api_response()
  end

  # APIs used in code generations

  @doc false
  defun ensure_filestore_models_given!(filestore_models :: term) :: [module] do
    [_ | _] = filestore_models0 ->
      filestore_models1 = Enum.uniq(filestore_models0)
      Enum.each(filestore_models1, &Blick.Dodai.Model.Filestore.ensure_filestore_model_module!/1)
      filestore_models1
    _otherwise ->
      raise(ArgumentError, message: "Non-empty :filestore_models list must be given in order to use SolomonAcs.Dodai.Repo.Filestore")
  end

  @doc false
  defun collection_name!(_gear_name :: SolomonLib.GearName.t, model_module :: v[atom]) :: CollectionName.t do
    # top_module_str = SolomonCore.GearModule.top(gear_name) |> Macro.to_string()
    top_module_str = "Blick"
    case Module.split(model_module) do
      [^top_module_str, "Repo", model_name] ->
        if !CollectionName.valid?(model_name), do: raise "#{model_name} is invalid as a Dodai collection name"
        model_name
      _otherwise ->
        raise "Filestore Repo module must be in `#{top_module_str}.Repo.SomeModel` format."
    end
  end

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      gear_name            = Mix.Project.config()[:app]
      dodai_gear_module    = SolomonAcs.Dodai.GearModule.get!(gear_name)
      filestore_models     = RF.ensure_filestore_models_given!(opts[:filestore_models])
      model_type_union_ast = filestore_models |> Enum.map(fn m -> quote do: unquote(m).t end) |> Croma.TypeUtil.list_to_type_union()

      @collection_name  RF.collection_name!(gear_name, __MODULE__)
      @default_group_id dodai_gear_module.default_group_id()
      @client           dodai_gear_module.client(Keyword.get(opts, :client_config, %{}))
      @shared?          Keyword.get(opts, :shared?, false)

      # @doc CodeUtil.doc_by_mfa!(RF, :insert, 7)
      @spec insert(RF.insert_action_t, String.t, GroupId.t) :: R.t(unquote(model_type_union_ast))
      def insert(insert_action, key, group_id) do
        RF.insert(insert_action, key, group_id, @client, @collection_name, @shared?, unquote(filestore_models))
      end

      # @doc CodeUtil.doc_by_mfa!(RF, :update, 8)
      @spec update(RF.update_action_t, GenericEntityId.t, String.t, GroupId.t) :: R.t(unquote(model_type_union_ast))
      def update(update_action, id, key, group_id) do
        RF.update(update_action, id, key, group_id, @client, @collection_name, @shared?, unquote(filestore_models))
      end

      # @doc CodeUtil.doc_by_mfa!(RF, :notify_upload_finish, 7)
      @spec notify_upload_finish(GenericEntityId.t, String.t, GroupId.t) :: R.t(unquote(model_type_union_ast))
      def notify_upload_finish(id, key, group_id) do
        RF.notify_upload_finish(id, key, group_id, @client, @collection_name, @shared?, unquote(filestore_models))
      end

      # @doc CodeUtil.doc_by_mfa!(RF, :delete, 7)
      @spec delete(GenericEntityId.t, nil | non_neg_integer, String.t, GroupId.t) :: R.t(:no_content)
      def delete(id, version, key, group_id) do
        RF.delete(id, version, key, group_id, @client, @collection_name, @shared?)
      end

      # @doc CodeUtil.doc_by_mfa!(RF, :freeze, 6)
      @spec freeze(GenericEntityId.t, String.t, GroupId.t) :: R.t(:no_content)
      def freeze(id, key, group_id) do
        RF.freeze(id, key, group_id, @client, @collection_name, @shared?)
      end

      # @doc CodeUtil.doc_by_mfa!(RF, :drop_file_version, 7)
      @spec drop_file_version(GenericEntityId.t, String.t, String.t, GroupId.t) :: R.t(:no_content)
      def drop_file_version(id, version_id, key, group_id) do
        RF.drop_file_version(id, version_id, key, group_id, @client, @collection_name, @shared?)
      end

      # @doc CodeUtil.doc_by_mfa!(RF, :retrieve, 7)
      @spec retrieve(GenericEntityId.t, String.t, GroupId.t) :: R.t(unquote(model_type_union_ast))
      def retrieve(id, key, group_id) do
        RF.retrieve(id, key, group_id, @client, @collection_name, @shared?, unquote(filestore_models))
      end

      # @doc CodeUtil.doc_by_mfa!(RF, :retrieve_list, 7)
      @spec retrieve_list(RF.list_action_t, String.t, GroupId.t) :: R.t([unquote(model_type_union_ast)])
      def retrieve_list(list_action, key, group_id) do
        RF.retrieve_list(list_action, key, group_id, @client, @collection_name, @shared?, unquote(filestore_models))
      end

      # @doc CodeUtil.doc_by_mfa!(RF, :count, 6)
      @spec count(nil | Dodai.Query.t, String.t, GroupId.t) :: R.t(non_neg_integer)
      def count(query, key, group_id) do
        RF.count(query, key, group_id, @client, @collection_name, @shared?)
      end

      if @default_group_id do
        @doc Repo.doc_for_function_with_default_group_id(:insert, 3)
        @spec insert(RF.insert_action_t, String.t) :: R.t(unquote(model_type_union_ast))
        def insert(insert_action, key), do: insert(insert_action, key, @default_group_id)

        @doc Repo.doc_for_function_with_default_group_id(:update, 4)
        @spec update(RF.update_action_t, GenericEntityId.t, String.t) :: R.t(unquote(model_type_union_ast))
        def update(update_action, id, key), do: update(update_action, id, key, @default_group_id)

        @doc Repo.doc_for_function_with_default_group_id(:notify_upload_finish, 3)
        @spec notify_upload_finish(GenericEntityId.t, String.t) :: R.t(unquote(model_type_union_ast))
        def notify_upload_finish(id, key), do: notify_upload_finish(id, key, @default_group_id)

        @doc Repo.doc_for_function_with_default_group_id(:delete, 4)
        @spec delete(GenericEntityId.t, nil | non_neg_integer, String.t) :: R.t(:no_content)
        def delete(id, version, key), do: delete(id, version, key, @default_group_id)

        @doc Repo.doc_for_function_with_default_group_id(:freeze, 3)
        @spec freeze(GenericEntityId.t, String.t) :: R.t(:no_content)
        def freeze(id, key), do: freeze(id, key, @default_group_id)

        @doc Repo.doc_for_function_with_default_group_id(:drop_file_version, 4)
        @spec drop_file_version(GenericEntityId.t, String.t, String.t) :: R.t(:no_content)
        def drop_file_version(id, version_id, key), do: drop_file_version(id, version_id, key, @default_group_id)

        @doc Repo.doc_for_function_with_default_group_id(:retrieve, 3)
        @spec retrieve(GenericEntityId.t, String.t) :: R.t(unquote(model_type_union_ast))
        def retrieve(id, key), do: retrieve(id, key, @default_group_id)

        @doc Repo.doc_for_function_with_default_group_id(:retrieve_list, 3)
        @spec retrieve_list(RF.list_action_t, String.t) :: R.t([unquote(model_type_union_ast)])
        def retrieve_list(list_action, key), do: retrieve_list(list_action, key, @default_group_id)

        @doc Repo.doc_for_function_with_default_group_id(:count, 3)
        @spec count(nil | Dodai.Query.t, String.t) :: R.t(non_neg_integer)
        def count(query, key), do: count(query, key, @default_group_id)
      end

      # CollectionSetting APIs

      @read_permission      opts |> Keyword.get(:read_permission, :section_or_owner) |> CustomCollectionPermissionLevel.new() |> R.get!()
      @write_permission     opts |> Keyword.get(:write_permission, :section_or_owner) |> CustomCollectionPermissionLevel.new() |> R.get!()
      @volume_usage_counted opts |> Keyword.get(:volume_usage_counted, true) |> R.wrap_if_valid(Croma.Boolean) |> R.get!()
      @max_versions         opts |> Keyword.get(:max_versions, 1) |> R.wrap_if_valid(MaxVersions) |> R.get!()

      if @shared? do
        # @doc CodeUtil.doc_by_mfa!(RF, :create_shared_collection, 8)
        @spec create_collection(String.t, GroupId.t) :: R.t(Dodai.Model.CollectionSetting.t)
        def create_collection(root_key, group_id) do
          RF.create_shared_collection(@read_permission, @write_permission, @volume_usage_counted, @max_versions, root_key, group_id, @client, @collection_name)
        end

        # @doc CodeUtil.doc_by_mfa!(RF, :drop_shared_collection, 4)
        @spec drop_collection(String.t, GroupId.t) :: R.t(:no_content)
        def drop_collection(root_key, group_id) do
          RF.drop_shared_collection(root_key, group_id, @client, @collection_name)
        end

        if @default_group_id do
          @doc Repo.doc_for_function_with_default_group_id(:create_collection, 2)
          @spec create_collection(String.t) :: R.t(Dodai.Model.CollectionSetting.t)
          def create_collection(root_key), do: create_collection(root_key, @default_group_id)

          @doc Repo.doc_for_function_with_default_group_id(:drop_collection, 2)
          @spec drop_collection(String.t) :: R.t(:no_content)
          def drop_collection(root_key), do: drop_collection(root_key, @default_group_id)
        end
      else
        # @doc CodeUtil.doc_by_mfa!(RF, :create_dedicated_collection, 7)
        @spec create_collection(String.t) :: R.t(Dodai.Model.CollectionSetting.t)
        def create_collection(root_key) do
          RF.create_dedicated_collection(@read_permission, @write_permission, @volume_usage_counted, @max_versions, root_key, @client, @collection_name)
        end

        # @doc CodeUtil.doc_by_mfa!(RF, :drop_dedicated_collection, 3)
        @spec drop_collection(String.t) :: R.t(:no_content)
        def drop_collection(root_key) do
          RF.drop_dedicated_collection(root_key, @client, @collection_name)
        end
      end
    end
  end
end
