defmodule Riffle.CtxTest do
  use ExUnit.Case, async: true

  alias Riffle.Ctx
  alias Riffle.WaistHelpers

  # DD-2: the composite root is typed, not a bag. DD-6: no slot accumulates
  # perturbations or emissions -- they enter and leave, never stay. Each
  # invariant is its own test so a failure names its own claim.

  describe "the composite root" do
    test "invariant: the declared overlay is exactly the metadata slot" do
      assert Ctx.overlay_slots() == [:metadata]
    end

    test "invariant: every slot but the declared overlay carries a concrete type" do
      overlays =
        for {field, type} <- WaistHelpers.field_types!(Ctx), overlay_type?(type), do: field

      assert Enum.sort(overlays) == [:metadata]
    end

    test "invariant: no slot accumulates perturbations or emissions" do
      field_types = WaistHelpers.field_types!(Ctx)

      assert field_types != %{}

      # The positive control. None of the real slots reference a catalog type,
      # so without this the discriminator could stop working entirely and the
      # fence would still pass -- which is exactly what happened once already.
      assert references_catalog?(catalog_typed_slot())

      accumulators = for {field, type} <- field_types, references_catalog?(type), do: field

      assert accumulators == []
    end
  end

  describe "new/1" do
    test "success: a new context starts pending, error-free, and carries its options" do
      ctx = Ctx.new(run_id: "run-1", metadata: %{source: "fixture"})

      assert ctx.run_id == "run-1"
      assert ctx.status == :pending
      assert ctx.errors == []
      assert ctx.input == nil
      assert ctx.output == nil
      assert ctx.metadata == %{source: "fixture"}
    end

    test "failure: an unrecognised option is rejected rather than discarded" do
      assert_raise ArgumentError, ~r/unknown keys \[:metadatra\]/, fn ->
        Ctx.new(run_id: "run-1", metadatra: %{source: "fixture"})
      end
    end

    test "failure: a context without a run id is refused, naming what is missing" do
      assert_raise KeyError, ~r/key :run_id not found/, fn -> Ctx.new([]) end
    end
  end

  describe "reads" do
    test "success: the typed slots answer with what was threaded into them" do
      ctx = Ctx.new(run_id: "run-1")

      assert ctx.input == nil
      assert ctx.output == nil
      refute Ctx.has_errors?(ctx)
    end

    test "success: a metadata read distinguishes absent from present-and-nil" do
      ctx = Ctx.new(run_id: "run-1", metadata: %{present: nil})

      assert Ctx.fetch_metadata(ctx, :present) == {:ok, nil}
      assert Ctx.fetch_metadata(ctx, :absent) == :error
    end
  end

  # A bare map type is an overlay. A struct type is also an Erlang map type, so
  # the __struct__ key is what separates "typed value" from "free-form bag".
  defp overlay_type?({:type, _, :map, :any}), do: true

  defp overlay_type?({:type, _, :map, fields}) when is_list(fields),
    do: not struct_fields?(fields)

  defp overlay_type?(_type), do: false

  defp struct_fields?(fields) do
    Enum.any?(fields, &match?({:type, _, :map_field_exact, [{:atom, _, :__struct__}, _]}, &1))
  end

  defp references_catalog?(type) do
    type |> WaistHelpers.remote_modules() |> Enum.any?(&WaistHelpers.catalog_module?/1)
  end

  # What a slot accumulating catalog types would look like in the typespec.
  # Taken from a real compiled typespec rather than hand-built, so if the Erlang
  # type representation ever changes, the control breaks and says so.
  defp catalog_typed_slot do
    {:type, {:t, definition, []}} = WaistHelpers.fetch_type!(Riffle.Ctx.Perturbation, :t)

    definition
  end
end
