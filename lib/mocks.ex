use Croma

defmodule Blick.Mocks do
  @moduledoc """
  Entirely replaces specified modules with mock modules, allowing test-time dependency injection.

  As a prerequisite, modules you want to replace must be behaviour modules.
  And only functions that appear in original modules' callback list can (and must) be mocked.
  If any of the callbacks are not implemented by the replacement, it fails.

  This effectively uses callback list as "contract", making this whole schema
  ["mocks based on explicit contracts"](http://blog.plataformatec.com.br/2015/10/mocks-and-explicit-contracts/).

  Although, sometimes you want to mock modules that you cannot touch (i.e. deps),
  so it allows mocking modules with plain public functions if insisted so. Set `exports_as_contract: true`.
  In this case, you do not have to mock all public functions exported.

  Unlike [`mox`], this allows:

  - mocking internal modules, not just front-end ones
      - i.e. If consumer-facing `API.fun` calls internal (though exported) `Internal.fun`,
        you can replace `Internal` with your mock implementation,
        test `API.fun` with internal parts mocked.
      - This is very useful when `Internal.fun` normally does some heavy work or external service calls.
  - clearer (IMHO) approach to DI-style mocking

  As a drawback, you cannot `expect/stub` functions from test codes in ad-hoc way.
  Your mock modules must actually work without any instructions at test-time.

  To enable replacing, call `#{inspect(__MODULE__)}.inject/2` from your test_helper.exs like so:

      # test_helper.exs
      #{inspect(__MODULE__)}.inject [
        {YourGear.SomeModule, SomeModuleMock},
        {YourGear.AnotherModule, AnotherModuleMock, exports_as_contract: true},
      ]

  # Options

  - `:load_paths` - Paths to search mock modules, relative to `test/`. Defaults to `["stub", "mock"]`

  """

  alias Croma.Result, as: R

  def inject(modules_and_replacements, opts \\ []) do
    Code.compiler_options(ignore_module_conflict: true)
    load_files_in_paths(opts[:load_paths])
    |> replace_modules(modules_and_replacements)
  end

  @default_load_paths ["stub", "mock"]

  defp load_files_in_paths([_ | _] = paths) do
    Enum.flat_map(paths, fn path_under_test ->
      Path.absname("test/#{path_under_test}/**/*.ex")
      |> Path.wildcard()
      |> Enum.flat_map(&Code.require_file/1)
    end)
  end
  defp load_files_in_paths(nil) do
    load_files_in_paths(@default_load_paths)
  end
  defp load_files_in_paths(_otherwise) do
    raise(":load_paths must be a list")
  end

  defp replace_modules(loaded_modules, modules_and_replacements) do
    modules_and_replacements
    |> ensure_all_replacements_are_loaded(loaded_modules)
    |> Enum.map(&redefine_module_delegating_to_replacement/1)
  end

  defp ensure_all_replacements_are_loaded(modules_and_replacements, loaded_modules) do
    loaded_module_names = Enum.map(loaded_modules, &elem(&1, 0))
    Enum.map(modules_and_replacements, fn mr ->
      replacement = elem(mr, 1)
      if replacement in loaded_module_names do
        mr
      else
        raise("Replacement module #{inspect(replacement)} does not exist.")
      end
    end)
  end

  defp redefine_module_delegating_to_replacement({mod, replacement}) do
    redefine_module_delegating_to_replacement({mod, replacement, exports_as_contract: false})
  end
  defp redefine_module_delegating_to_replacement({mod, replacement, opts}) do
    if Keyword.get(opts, :exports_as_contract, false) do
      check_callbacks(mod, replacement) |> R.or_else(check_exports(mod, replacement))
    else
      check_callbacks(mod, replacement)
    end
    |> redefine_or_raise()
  end

  defp redefine_or_raise({:ok, {mod, replacement, mocked_functions}}), do: redefine_impl(mod, replacement, mocked_functions)
  defp redefine_or_raise({:error, e}), do: raise("Invalid mocks! #{inspect(e)}")

  defp check_callbacks(mod, replacement) do
    try do
      {:ok, mod.behaviour_info(:callbacks)}
    rescue
      UndefinedFunctionError -> {:error, {:not_behaviour, mod}}
    end
    |> R.bind(&(check_callbacks_impl(&1, mod, replacement)))
  end

  defp check_callbacks_impl(callbacks, mod, replacement) do
    implemented_functions = replacement.__info__(:functions)
    case Enum.reject(callbacks, &(&1 in implemented_functions)) do
      [] -> {:ok, {mod, replacement, callbacks}}
      not_implemented -> {:error, {:implementation_missing, not_implemented}}
    end
  end

  defp check_exports(mod, replacement) do
    MapSet.new(mod.__info__(:functions))
    |> MapSet.intersection(MapSet.new(replacement.__info__(:functions)))
    |> MapSet.to_list()
    |> case do
      [] ->
        {:error, {:no_exports_implemented, replacement}}
      mocked_functions ->
        {:ok, {mod, replacement, mocked_functions}}
    end
  end

  defp redefine_impl(mod, replacement, mocked_functions) do
    mocked_module_contents =
      quote bind_quoted: [replacement: replacement, funs: mocked_functions] do
        for {name, arity} <- funs do
          vars = Blick.Mocks.make_vars(arity, __MODULE__)
          defdelegate unquote(name)(unquote_splicing(vars)), to: replacement
        end
      end
    {:module, name, _binary, _exports} = Module.create(mod, mocked_module_contents, Macro.Env.location(__ENV__))
    name
  end

  @doc false
  def make_vars(n, module) do
    if n == 0 do
      []
    else
      Enum.map(0..(n - 1), fn i -> Macro.var(String.to_atom("arg#{i}"), module) end)
    end
  end
end
