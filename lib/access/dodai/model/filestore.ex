use Croma

defmodule Blick.Dodai.Model.Filestore do
  @moduledoc """
  Helper module to define data structure that represents Dodai file entities with the help of `Croma.Struct`.

  See `SolomonAcs.Dodai.Model` for basic concepts and options.

  Note that `public_url` field will be implicitly converted to `https://` variant since why not?

  ## Usage

      defmodule YourGear.Model.SomeModel do
        use #{inspect(__MODULE__)}, [
          id_pattern:  ~r/^id_\\d{10}$/,
          data_fields: [
            f1: Croma.String,
          ],
        ]
      end

  For Filestore, you may often use neither `:id_pattern` nor `:data_fields`, but it is OK.
  """

  alias Croma.Result, as: R
  import Croma.TypeGen
  alias Blick.Dodai.Repo.Filestore, as: RF
  alias __MODULE__, as: MF

  defmodule FileVersion do
    use Croma.Struct, accept_case: :lower_camel, recursive_new?: true, fields: [
      version_id: Croma.String,
      size:       Croma.NonNegInteger,
      created_at: SolomonLib.Time,
    ]
  end

  defmodule DeleteMarker do
    use Croma.Struct, accept_case: :lower_camel, recursive_new?: true, fields: [
      version_id: Croma.String,
      created_at: SolomonLib.Time,
    ]
  end

  defmodule PublicUrl do
    @type t :: String.t

    defun valid?(v :: term) :: boolean do
      "http://" <> _ -> false
      "https://" <> _ -> true
      _otherwise -> false
    end

    defun new(v :: term) :: R.t(t) do
      "http://" <> http_url       -> {:ok, "https://" <> http_url}
      "https://" <> _ = https_url -> {:ok, https_url}
      _otherwise                  -> {:error, {:invalid_value, [__MODULE__]}}
    end
  end

  @doc """
  Validates user defined fields (`:_id`, `:data`) in `insert_action`.
  """
  defun validate_on_insert(insert_action :: RF.insert_action_t,
                           model         :: m,
                           id_module     :: v[module],
                           data_module   :: v[module]) :: R.t({m, RF.insert_action_t}) when m: module do
    R.m do
      i   <- id_module.validate_on_insert(insert_action[:_id]) # Can be nil on insert
      i_a <- validate_data_field(insert_action, data_module)   # Optional for File entities
      pure {model, Map.put(i_a, :_id, i)}
    end
  end

  defp validate_data_field(%{data: data} = action, data_module) do
    data_module.new(data)
    |> R.map(fn valid_data -> %{action | data: valid_data} end)
  end
  defp validate_data_field(action_without_data, _data_module) do
    {:ok, action_without_data}
  end

  # APIs used in code generations

  @doc false
  defun ensure_filestore_model_module!(filestore_model :: v[module]) :: :ok do
    exports = filestore_model.module_info(:exports) # `filestore_model` will be compiled and loaded if necessary; raises if not existing
    if {:validate_on_insert, 1} in exports do
      :ok
    else
      raise(ArgumentError, message: "#{inspect(filestore_model)} is invalid as a Filestore model module. Use #{inspect(__MODULE__)} to define valid one.")
    end
  end

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      defmodule Id do
        use SolomonAcs.Dodai.EntityId, pattern: opts[:id_pattern]
      end

      defmodule Data do
        use Croma.Struct, fields: Keyword.get(opts, :data_fields, []), recursive_new?: true
      end

      use Croma.Struct, accept_case: :lower_camel, recursive_new?: true, fields: [
        _id:           Id,
        created_at:    SolomonLib.Time,
        updated_at:    SolomonLib.Time,
        owner:         Dodai.Owner,
        sections:      Dodai.Sections,
        version:       Croma.NonNegInteger,
        data:          Data,
        filename:      Croma.String,
        content_type:  Croma.String,
        public_url:    nilable(PublicUrl),
        upload_url:    nilable(SolomonLib.Url),
        upload_form:   nilable(Croma.Map),
        download_url:  nilable(SolomonLib.Url),
        file_versions: list_of(union([FileVersion, DeleteMarker])),
      ]

      # @doc SolomonLib.CodeUtil.doc_by_mfa!(MF, :validate_on_insert, 4)
      defun validate_on_insert(insert_action :: RF.insert_action_t) :: R.t({__MODULE__, RF.insert_action_t}) do
        MF.validate_on_insert(insert_action, __MODULE__, Id, Data)
      end
    end
  end
end
