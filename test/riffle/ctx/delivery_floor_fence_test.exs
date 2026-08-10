defmodule Riffle.Ctx.DeliveryFloorFenceTest do
  use ExUnit.Case, async: true

  alias Riffle.Ctx
  alias Riffle.Ctx.Emission
  alias Riffle.Ctx.Knot
  alias Riffle.Ctx.Perturbation

  # AC-02.3. Delivery is total: an accepted perturbation never vanishes without
  # an observable trace. The fence enumerates the whole catalog and builds each
  # perturbation generically, so a type added tomorrow is covered the moment it
  # joins the registry -- no hand-maintained list to fall behind, and no
  # allowlist of types exempt from the floor.

  defmodule NotInTheCatalog do
    @moduledoc false
    defstruct []
  end

  defmodule Impostor do
    @moduledoc false
    @behaviour Riffle.Ctx.Catalog

    defstruct []

    @impl true
    def tag, do: :impostor
  end

  setup do
    %{ctx: Ctx.new(run_id: "delivery-floor")}
  end

  test "fence: every catalog perturbation yields a real emission, never the floor", %{ctx: ctx} do
    results =
      Enum.map(Perturbation.implementations(), fn module ->
        {module, Knot.tick(ctx, sample(module))}
      end)

    assert results != []

    silent = for {module, {_ctx, []}} <- results, do: module

    assert silent == []

    # A type the knot has no clause for still yields an emission -- the floor
    # sees to that -- so "yields something" alone would pass while the type was
    # quietly default-passing. The floor is the runtime net; drift fails here.
    defaulted =
      for {module, {_ctx, emissions}} <- results,
          Enum.any?(emissions, &match?(%Emission.DefaultPassed{}, &1)),
          do: module

    assert defaulted == []
  end

  test "failure: a struct that declares a tag it never registered is named and refused", %{
    ctx: ctx
  } do
    assert_raise ArgumentError, ~r/declares tag :impostor but is not registered/, fn ->
      Knot.tick(ctx, %Impostor{})
    end
  end

  test "failure: a struct with no tag at all cannot reach the catalog check", %{ctx: ctx} do
    assert_raise UndefinedFunctionError, ~r/NotInTheCatalog\.tag\/0 is undefined/, fn ->
      Knot.tick(ctx, %NotInTheCatalog{})
    end
  end

  # A struct built from the module's own fields: the fence never names them, so
  # it cannot drift from the catalog.
  defp sample(module) do
    fields = module |> struct() |> Map.from_struct() |> Map.keys()

    struct!(module, Map.new(fields, &{&1, sample_value(&1)}))
  end

  defp sample_value(:level), do: :debug
  defp sample_value(:message), do: "sample"
  defp sample_value(:stage), do: :sample_stage
  defp sample_value(:key), do: :sample_key
  defp sample_value(_field), do: :sample
end
