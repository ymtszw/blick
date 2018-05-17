instance_dep = {:antikythera_acs, [git: "git@github.com:access-company/antikythera_acs.git"]}

try do
  parent_dir = Path.expand("..", __DIR__)
  deps_dir =
    case Path.basename(parent_dir) do
      "deps" -> parent_dir                 # this gear project is used by another gear as a gear dependency
      _      -> Path.join(__DIR__, "deps") # this gear project is the toplevel mix project
    end
  Code.require_file(Path.join([deps_dir, "antikythera", "mix_common.exs"]))

  defmodule Blick.Mixfile do
    use Antikythera.GearProject, [
      antikythera_instance_dep: instance_dep,
      source_url:           "https://github.com/ymtszw/blick",
    ]

    defp gear_name(), do: :blick
    defp version()  , do: "0.0.1"
    defp gear_deps() do
      []
    end
  end
rescue
  _any_error ->
    defmodule AntikytheraGearInitialSetup.Mixfile do
      use Mix.Project

      def project() do
        [
          app:  :just_to_fetch_antikythera_instance_as_a_dependency,
          deps: [unquote(instance_dep)],
        ]
      end
    end
end
