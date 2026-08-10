defmodule Riffle.Ctx.KnotTest do
  use ExUnit.Case, async: true

  alias Riffle.Ctx
  alias Riffle.Ctx.Emission
  alias Riffle.Ctx.Knot
  alias Riffle.Ctx.Perturbation
  alias Riffle.FenceHelpers

  @sequence [
    %Perturbation.RunStarted{},
    %Perturbation.InputReceived{payload: [:a, :b]},
    %Perturbation.StageEntered{stage: :sense},
    %Perturbation.MetadataRecorded{key: :source, value: "fixture"},
    %Perturbation.StageProgressed{stage: :sense, progress: 1},
    %Perturbation.StageExited{stage: :sense, output: [:a]},
    %Perturbation.ErrorReported{error: :b_rejected},
    %Perturbation.DiagnosticReported{level: :debug, message: "one dropped"},
    %Perturbation.RunCompleted{output: [:a]}
  ]

  # The trajectory the sequence above is contracted to produce: the status after
  # each tick, and the emission tags that tick fired. Pinned rather than compared
  # to a second run of itself -- comparing a fold to itself proves determinism,
  # which the purity fence already proves far more strongly, while saying nothing
  # about whether the trajectory is the right one.
  @trajectory [
    {:running, [:status_changed]},
    {:running, [:input_set]},
    {:running, [:stage_started]},
    {:running, [:metadata_set]},
    {:running, [:stage_progress]},
    {:running, [:stage_completed]},
    {:running, [:error_raised]},
    {:running, [:diagnostic]},
    {:completed, [:status_changed, :output_produced]}
  ]

  setup do
    %{ctx: Ctx.new(run_id: "knot")}
  end

  describe "tick/2" do
    test "invariant: the same perturbation against the same ctx yields the same pinned result", %{
      ctx: ctx
    } do
      perturbation = %Perturbation.MetadataRecorded{key: :source, value: "fixture"}

      {stepped, emissions} = Knot.tick(ctx, perturbation)

      assert stepped.metadata == %{source: "fixture"}
      assert emissions == [%Emission.MetadataSet{key: :source, value: "fixture"}]
      assert Knot.tick(ctx, perturbation) == {stepped, emissions}
    end

    test "invariant: the knot emits the full stream and takes no consumer argument", %{ctx: ctx} do
      assert FenceHelpers.exports?(Knot, :tick, 2)
      refute FenceHelpers.exports?(Knot, :tick, 3)

      {_ctx, emissions} = Knot.tick(ctx, %Perturbation.RunCompleted{output: :done})

      assert emissions == [
               %Emission.StatusChanged{from: :pending, to: :completed},
               %Emission.OutputProduced{payload: :done}
             ]
    end

    test "invariant: a recorded perturbation sequence replays to the pinned trajectory", %{
      ctx: ctx
    } do
      assert trajectory(ctx, @sequence) == @trajectory
    end

    test "success: a run threads status, input, metadata, errors, and output through the sequence",
         %{ctx: ctx} do
      {final, _emissions} = fold(ctx, @sequence)

      assert final.status == :completed
      assert final.input == [:a, :b]
      assert final.output == [:a]
      assert final.errors == [:b_rejected]
      assert Ctx.fetch_metadata(final, :source) == {:ok, "fixture"}
      assert Ctx.has_errors?(final)
    end

    test "success: a status transition reports where it came from and where it went", %{ctx: ctx} do
      {running, emissions} = Knot.tick(ctx, %Perturbation.RunStarted{})

      assert running.status == :running
      assert emissions == [%Emission.StatusChanged{from: :pending, to: :running}]
    end

    test "success: a failed run accumulates its reason and reports both facts", %{ctx: ctx} do
      {failed, emissions} = Knot.tick(ctx, %Perturbation.RunFailed{reason: :upstream_timeout})

      assert failed.status == :failed
      assert failed.errors == [:upstream_timeout]

      assert emissions == [
               %Emission.StatusChanged{from: :pending, to: :failed},
               %Emission.ErrorRaised{error: :upstream_timeout}
             ]
    end

    test "invariant: the context is threaded, never mutated -- the original is untouched", %{
      ctx: ctx
    } do
      {next, _emissions} = Knot.tick(ctx, %Perturbation.InputReceived{payload: :fresh})

      assert ctx.input == nil
      assert next.input == :fresh
    end
  end

  defp trajectory(ctx, perturbations) do
    perturbations
    |> Enum.scan({ctx, []}, fn perturbation, {acc, _emissions} -> Knot.tick(acc, perturbation) end)
    |> Enum.map(fn {stepped, emissions} ->
      {stepped.status, Enum.map(emissions, & &1.__struct__.tag())}
    end)
  end

  defp fold(ctx, perturbations) do
    Enum.reduce(perturbations, {ctx, []}, fn perturbation, {acc, emitted} ->
      {stepped, emissions} = Knot.tick(acc, perturbation)
      {stepped, emitted ++ emissions}
    end)
  end
end
