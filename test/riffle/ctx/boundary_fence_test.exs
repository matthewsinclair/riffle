defmodule Riffle.Ctx.BoundaryFenceTest do
  use ExUnit.Case, async: true

  # DD-5: the waist and the engine are independent, and the fence runs in both
  # directions. The engine is a rules engine, which is inference, which lives at
  # an edge -- so neither half may name the other, and they compose only where
  # an edge component joins them (ST0003). Fencing one direction only would let
  # the waist grow a dependency on the engine while the engine stayed clean.
  #
  # The non-empty assertion is load-bearing: a fence over an empty file set
  # passes for the wrong reason.

  @engine_namespace "Riffle." <> "Predicate"
  @waist_namespace "Riffle." <> "Ctx"

  test "fence: the waist names no engine module" do
    assert_namespace_absent(waist_sources(), @engine_namespace)
  end

  test "fence: the engine names no waist module" do
    assert_namespace_absent(engine_sources(), @waist_namespace)
  end

  defp assert_namespace_absent(sources, namespace) do
    assert sources != []

    offending = Enum.filter(sources, &(&1 |> File.read!() |> String.contains?(namespace)))

    assert offending == []
  end

  defp waist_sources, do: Path.wildcard("lib/riffle/ctx/**/*.ex")

  defp engine_sources, do: Path.wildcard("lib/riffle/predicate/**/*.ex")
end
