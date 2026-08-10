defmodule Riffle.BoundaryFenceTest do
  use ExUnit.Case, async: true

  alias Riffle.FenceHelpers

  # DD-5: the waist and the engine are independent, and the fence runs in both
  # directions. The engine is a rules engine, which is inference, which lives at
  # an edge -- so neither half may name the other, and they compose only where
  # an edge component joins them (ST0003).
  #
  # This reads each file's parsed AST, not its text. A text scan for the
  # namespace is defeated by `alias Riffle.{Ctx, Foo}`, which never produces the
  # substring -- and that brace form is already idiomatic in the very files this
  # fence scans. It also cannot tell a dependency from a moduledoc that happens
  # to mention the other half.
  #
  # The purity fence's call-closure walk is the stronger instrument for the
  # waist-to-engine direction, and both are kept: the closure catches a call at
  # any depth but is blind to a name that never becomes one, and it can only be
  # walked forward from the knot, so the engine-to-waist direction has no
  # closure to walk at all.
  #
  # The non-empty assertion is load-bearing: a fence over an empty file set
  # passes for the wrong reason.

  test "fence: the waist names no engine module" do
    assert_namespace_absent(FenceHelpers.waist_sources(), FenceHelpers.engine_namespace())
  end

  test "fence: the engine names no waist module" do
    assert_namespace_absent(FenceHelpers.engine_sources(), FenceHelpers.waist_namespace())
  end

  # The pattern layer is the edge where the two halves meet (ST0003 DD-1). It
  # names both; neither may name it. The engine direction is the stitch from the
  # handoff: the source engine hardcoded a fallback to the pattern layer's own
  # default-pipeline module, guarded by `Code.ensure_loaded?`, so the engine
  # could not be used without the layer it was supposed to be independent of.
  # Severing it was ST0001's job and it is config injection now; this is what
  # stops it re-forming, and it only became checkable once a pattern layer
  # existed to be named.

  test "fence: the engine names no pattern-layer module" do
    assert_namespace_absent(
      FenceHelpers.engine_sources(),
      FenceHelpers.pattern_layer_namespace()
    )
  end

  test "fence: the waist names no pattern-layer module" do
    assert_namespace_absent(FenceHelpers.waist_sources(), FenceHelpers.pattern_layer_namespace())
  end

  test "invariant: the AST walk sees a module named through the brace-alias form" do
    # The positive control. Without it the fence above could go dead the moment
    # the walk stopped resolving names, and still pass.
    path = Path.join(System.tmp_dir!(), "riffle_boundary_fence_probe.ex")

    File.write!(
      path,
      "defmodule Probe do\n  alias Riffle.{Ctx, Ctx.Knot}\n  def run, do: {Ctx, Knot}\nend\n"
    )

    named = FenceHelpers.named_modules(path)

    File.rm!(path)

    assert FenceHelpers.waist_namespace() in named
    assert (FenceHelpers.waist_namespace() <> ".Knot") in named
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
