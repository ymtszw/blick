solomon_instance_dep = {:solomon_acs, [git: "git@github.com:access-company/solomon_acs.git"]}

try do
  parent_dir = Path.expand("..", __DIR__)
  deps_dir =
    case Path.basename(parent_dir) do
      "deps" -> parent_dir                 # this gear project is used by another gear as a gear dependency
      _      -> Path.join(__DIR__, "deps") # this gear project is the toplevel mix project
    end
  Code.require_file(Path.join([deps_dir, "solomon", "mix_common.exs"]))

  defmodule Blick.Mixfile do
    use Solomon.GearProject, [
      solomon_instance_dep: solomon_instance_dep,
      source_url:           "https://bitbucket.org/aYuMatsuzawa/blick",
    ]

    defp gear_name(), do: :blick
    defp version()  , do: "0.0.1"
    defp gear_deps() do
      [
        {:gear_lib, [git: "git@github.com:access-company/gear_lib.git"]},
      ]
    end
  end
rescue
  _any_error ->
    defmodule SolomonGearInitialSetup.Mixfile do
      use Mix.Project

      def project() do
        [
          app:  :just_to_fetch_solomon_instance_as_a_dependency,
          deps: [unquote(solomon_instance_dep)],
        ]
      end
    end
end
