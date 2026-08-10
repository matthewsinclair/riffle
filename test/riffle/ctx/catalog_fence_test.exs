defmodule Riffle.Ctx.CatalogFenceTest do
  use ExUnit.Case, async: true

  alias Riffle.Ctx.Emission
  alias Riffle.Ctx.Perturbation
  alias Riffle.WaistHelpers

  # DD-3: each catalog is a closed registry. The bijection fence enumerates the
  # source of truth on both sides -- the struct modules on disk and the
  # implementations the registry declares -- so a struct authored without a
  # registry entry fails the build instead of becoming an invisible type.
  #
  # One test per catalog: a shared test would short-circuit on the first
  # failure and never say whether one catalog or both had drifted.

  test "fence: the perturbation catalog's modules on disk are exactly its declared implementations" do
    assert_catalog_bijection(Perturbation)
  end

  test "fence: the emission catalog's modules on disk are exactly its declared implementations" do
    assert_catalog_bijection(Emission)
  end

  # Membership is written twice in each catalog file: as the implementations
  # list and again as the `t()` union. The union stays hand-written because a
  # generated one is invisible to a reader and to ExDoc, in a module whose whole
  # job is a legible typed surface -- so the second copy is fenced instead.
  test "fence: the perturbation catalog's union type names exactly its implementations" do
    assert_union_matches_membership(Perturbation)
  end

  test "fence: the emission catalog's union type names exactly its implementations" do
    assert_union_matches_membership(Emission)
  end

  test "invariant: an unknown tag loud-fails at the perturbation catalog" do
    assert Perturbation.fetch_by_tag(:no_such_tag) == :error
  end

  test "invariant: an unknown tag loud-fails at the emission catalog" do
    assert Emission.fetch_by_tag(:no_such_tag) == :error
  end

  defp assert_union_matches_membership(catalog) do
    {:type, {:t, definition, []}} = WaistHelpers.fetch_type!(catalog, :t)

    union = definition |> WaistHelpers.remote_modules() |> Enum.sort()

    assert union != []
    assert union == Enum.sort(catalog.implementations())
  end

  defp assert_catalog_bijection(catalog) do
    on_disk =
      catalog
      |> WaistHelpers.catalog_dir()
      |> Path.join("*.ex")
      |> Path.wildcard()
      |> Enum.map(&WaistHelpers.catalog_module(catalog, &1))
      |> Enum.filter(&WaistHelpers.struct_module?/1)
      |> Enum.sort()

    declared = Enum.sort(catalog.implementations())

    assert on_disk != []
    assert on_disk == declared

    tags = Enum.map(declared, & &1.tag())

    assert tags == Enum.uniq(tags)
    assert Enum.map(tags, &catalog.fetch_by_tag/1) == Enum.map(declared, &{:ok, &1})
  end
end
