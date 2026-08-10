defmodule Riffle.CtxTest do
  use ExUnit.Case, async: true

  alias Riffle.Ctx

  # DD-2: the composite root is typed, not a bag. The fence reads the declared
  # `t()` typespec rather than trusting the struct's runtime values, so a slot
  # typed `map()` cannot hide behind a well-behaved default. DD-6: no slot
  # accumulates perturbations or emissions -- they enter and leave, never stay.

  describe "the composite root" do
    test "invariant: the composite root is typed, with one declared overlay and no event accumulation" do
      field_types = field_types!(Ctx)

      assert field_types != %{}

      overlays = for {field, type} <- field_types, overlay_type?(type), do: field

      assert Enum.sort(overlays) == Enum.sort(Ctx.overlay_slots())
      assert length(Ctx.overlay_slots()) <= 1

      accumulators = for {field, type} <- field_types, references_catalog?(type), do: field

      assert accumulators == []
    end

    test "success: a new context starts pending, error-free, and carries its options" do
      ctx = Ctx.new(run_id: "run-1")

      assert ctx.status == :pending
      assert ctx.errors == []
      assert ctx.metadata == %{}
      assert ctx.run_id == "run-1"
    end

    test "success: reads on the composite root answer from the declared slots" do
      ctx = Ctx.new(run_id: "run-1")

      assert Ctx.get_input(ctx) == nil
      assert Ctx.get_output(ctx) == nil
      assert Ctx.get_metadata(ctx, :absent) == nil
      refute Ctx.has_errors?(ctx)
    end
  end

  # -- typespec introspection -------------------------------------------------

  defp field_types!(module) do
    {:ok, types} = Code.Typespec.fetch_types(module)

    {:type, {:t, {:type, _line, :map, fields}, []}} =
      Enum.find(types, &match?({:type, {:t, _, []}}, &1))

    fields
    |> Map.new(fn {:type, _, :map_field_exact, [{:atom, _, field}, type]} -> {field, type} end)
    |> Map.delete(:__struct__)
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
    type |> remote_modules() |> Enum.any?(&catalog_module?/1)
  end

  defp remote_modules({:remote_type, _, [{:atom, _, module}, args]}) do
    [module | Enum.flat_map(args, &remote_modules/1)]
  end

  defp remote_modules({:type, _, _kind, args}) when is_list(args),
    do: Enum.flat_map(args, &remote_modules/1)

  defp remote_modules({:ann_type, _, args}) when is_list(args),
    do: Enum.flat_map(args, &remote_modules/1)

  defp remote_modules({:user_type, _, _name, args}) when is_list(args),
    do: Enum.flat_map(args, &remote_modules/1)

  defp remote_modules(_type), do: []

  # Atom.to_string rather than Module.split/1: the walk can surface an Erlang
  # module, which Module.split/1 raises on.
  defp catalog_module?(module) do
    String.starts_with?(Atom.to_string(module), [
      "Elixir.Riffle.Ctx.Perturbation",
      "Elixir.Riffle.Ctx.Emission"
    ])
  end
end
