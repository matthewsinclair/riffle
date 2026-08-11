defmodule Riffle.Cli.ThinCoordinatorFenceTest do
  use ExUnit.Case, async: true

  alias Riffle.FenceHelpers

  # hv's architecture ruling, 2026-08-11: business logic lives in a service
  # module, and the CLI and the mix task are thin coordinators over it.
  #
  # "Thin coordinator" is otherwise a style assertion, and style assertions
  # decay the first time someone is in a hurry. Reaching past the service
  # straight to `Riffle.Sia` is always locally convenient -- it is one alias and
  # one call, it works, and nothing complains. Six months later the business
  # logic is in the commands and the service is a pass-through nobody trusts.
  #
  # So the rule is mechanical instead: the CLI layer may name the service and
  # the CLI framework, and may name no engine, waist or pattern-layer module at
  # any depth. The layer is read off the parsed AST, and it includes the mix
  # task, which lives under lib/mix/tasks/ but is CLI-layer code wherever it
  # sits -- a fence scoped by directory rather than by role would let the one
  # file that is easiest to get wrong escape.
  #
  # The non-empty assertion is load-bearing: a fence over an empty file set
  # passes for the wrong reason, and this one's file set is assembled from two
  # globs, either of which could silently stop matching.

  test "fence: the CLI layer names no pattern-layer module" do
    assert_namespace_absent(FenceHelpers.cli_sources(), FenceHelpers.pattern_layer_namespace())
  end

  test "fence: the CLI layer names no waist module" do
    assert_namespace_absent(FenceHelpers.cli_sources(), FenceHelpers.waist_namespace())
  end

  test "fence: the CLI layer names no engine module" do
    assert_namespace_absent(FenceHelpers.cli_sources(), FenceHelpers.engine_namespace())
  end

  test "invariant: the CLI layer does reach the service, so the fence is not passing by absence" do
    # Three fences above all pass trivially if the CLI never names anything.
    # This is what makes them mean "reaches the system through the service"
    # rather than "reaches nothing at all".
    named =
      FenceHelpers.cli_sources()
      |> Enum.flat_map(&FenceHelpers.named_modules/1)
      |> Enum.uniq()

    assert FenceHelpers.service_namespace() in named
  end

  test "invariant: the file set covers both halves of the layer" do
    sources = FenceHelpers.cli_sources()

    assert Enum.any?(sources, &String.starts_with?(&1, "lib/riffle/cli/"))
    assert Enum.any?(sources, &String.starts_with?(&1, "lib/mix/tasks/"))
  end

  defp assert_namespace_absent(sources, namespace) do
    assert sources != []

    offending =
      Enum.filter(sources, fn source ->
        source |> FenceHelpers.named_modules() |> Enum.any?(&String.starts_with?(&1, namespace))
      end)

    assert offending == []
  end
end
