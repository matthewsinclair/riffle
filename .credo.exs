# Credo configuration for riffle.
#
# The gate is `mix credo --strict`, which is the whole fleet's catalogue row and
# is left at the default in bin/.devbin/config.yaml -- devbin runs the check,
# and what the check MEANS is configured here, where credo configuration
# belongs. A laxer command line in devbin's config would put a project style
# ruling in the launcher's file instead of the linter's.
#
# One check is disabled, deliberately and project-wide.
%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "test/", "mix.exs"]
      },
      strict: true,
      checks: %{
        disabled: [
          # Credo.Check.Design.AliasUsage flags `Foo.Bar.baz()` wherever an
          # `alias Foo.Bar` would shorten it. On first run it accounted for 44
          # of this project's 66 strict findings.
          #
          # Disabled for the same reason arca_config disabled it, where it was
          # 129 of 139: this codebase names modules in full at their call sites
          # on purpose. `Riffle.Predicate.Registry.handle_call` says which
          # registry, in a project whose whole subject is a predicate/expression
          # tree with several similarly-shaped modules; aliasing them at the top
          # of the invoking module moves that information away from the line
          # that depends on it.
          #
          # Project-wide rather than test-only, because a style ruling that
          # applies in one directory and not another is two rulings.
          {Credo.Check.Design.AliasUsage, []}
        ]
      }
    }
  ]
}
