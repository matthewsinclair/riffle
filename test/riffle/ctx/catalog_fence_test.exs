defmodule Riffle.Ctx.CatalogFenceTest do
  use ExUnit.Case, async: true

  alias Riffle.Ctx.Emission
  alias Riffle.Ctx.Perturbation

  # DD-3: each catalog is a closed registry. The bijection fence enumerates the
  # source of truth on both sides -- the struct modules that exist on disk and
  # the implementations the parent declares -- so a struct authored without a
  # registry entry fails the build instead of becoming an invisible type.

  test "fence: struct modules on disk are exactly the declared implementations, tags unique" do
    assert_catalog_bijection(Perturbation, "lib/riffle/ctx/perturbation")
    assert_catalog_bijection(Emission, "lib/riffle/ctx/emission")
  end

  test "invariant: an unknown tag loud-fails at both catalogs" do
    assert Perturbation.fetch_by_tag(:no_such_tag) == :error
    assert Emission.fetch_by_tag(:no_such_tag) == :error
  end

  defp assert_catalog_bijection(catalog, source_dir) do
    on_disk =
      source_dir
      |> Path.join("*.ex")
      |> Path.wildcard()
      |> Enum.map(&module_for(catalog, &1))
      |> Enum.filter(&struct_module?/1)
      |> Enum.sort()

    declared = Enum.sort(catalog.implementations())

    assert on_disk != []
    assert on_disk == declared

    tags = Enum.map(declared, & &1.tag())

    assert tags == Enum.uniq(tags)
    assert Enum.map(tags, &catalog.fetch_by_tag/1) == Enum.map(declared, &{:ok, &1})
  end

  defp module_for(catalog, path) do
    Module.concat(catalog, path |> Path.basename(".ex") |> Macro.camelize())
  end

  # The catalog directory also holds the Kind behaviour, which is not a type in
  # the registry. Filtering on "defines a struct" keeps the fence exact without
  # a hand-maintained exclusion list to drift.
  defp struct_module?(module) do
    Code.ensure_loaded!(module)
    function_exported?(module, :__struct__, 0)
  end
end
