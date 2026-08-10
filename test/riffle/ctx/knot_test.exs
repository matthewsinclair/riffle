defmodule Riffle.Ctx.KnotTest do
  use ExUnit.Case, async: true

  alias Riffle.Ctx
  alias Riffle.Ctx.Emission
  alias Riffle.Ctx.Knot
  alias Riffle.Ctx.Perturbation

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

  describe "tick/2" do
    test "invariant: the same perturbation against the same ctx yields identical results" do
      ctx = Ctx.new(run_id: "determinism")
      perturbation = %Perturbation.MetadataRecorded{key: :source, value: "fixture"}

      assert Knot.tick(ctx, perturbation) == Knot.tick(ctx, perturbation)
    end

    test "invariant: the knot emits the full stream and takes no consumer argument" do
      assert function_exported?(Knot, :tick, 2)
      refute function_exported?(Knot, :tick, 3)

      ctx = Ctx.new(run_id: "full-stream")

      {_ctx, emissions} = Knot.tick(ctx, %Perturbation.RunCompleted{output: :done})

      assert [
               %Emission.StatusChanged{from: :pending, to: :completed},
               %Emission.OutputProduced{payload: :done}
             ] =
               emissions
    end

    test "invariant: a recorded perturbation sequence replays to an identical trajectory" do
      ctx = Ctx.new(run_id: "replay")

      assert trajectory(ctx, @sequence) == trajectory(ctx, @sequence)
    end

    test "success: a run threads status, input, metadata, errors, and output through the sequence" do
      ctx = Ctx.new(run_id: "threading")

      {final, emissions} = fold(ctx, @sequence)

      assert final.status == :completed
      assert final.input == [:a, :b]
      assert final.output == [:a]
      assert final.errors == [:b_rejected]
      assert Ctx.get_metadata(final, :source) == "fixture"
      assert Ctx.has_errors?(final)

      assert Enum.map(emissions, & &1.__struct__.tag()) == [
               :status_changed,
               :input_set,
               :stage_started,
               :metadata_set,
               :stage_progress,
               :stage_completed,
               :error_raised,
               :diagnostic,
               :status_changed,
               :output_produced
             ]
    end

    test "success: a status transition reports where it came from and where it went" do
      ctx = Ctx.new(run_id: "transition")

      {running, [%Emission.StatusChanged{} = changed]} =
        Knot.tick(ctx, %Perturbation.RunStarted{})

      assert changed.from == :pending
      assert changed.to == :running
      assert running.status == :running
    end

    test "success: a failed run accumulates its reason and reports both facts" do
      ctx = Ctx.new(run_id: "failure")

      {failed, emissions} = Knot.tick(ctx, %Perturbation.RunFailed{reason: :upstream_timeout})

      assert failed.status == :failed
      assert failed.errors == [:upstream_timeout]

      assert [
               %Emission.StatusChanged{to: :failed},
               %Emission.ErrorRaised{error: :upstream_timeout}
             ] = emissions
    end

    test "invariant: the context is threaded, never mutated -- the original is untouched" do
      ctx = Ctx.new(run_id: "immutable")

      {next, _emissions} = Knot.tick(ctx, %Perturbation.InputReceived{payload: :fresh})

      assert ctx.input == nil
      assert next.input == :fresh
    end
  end

  defp trajectory(ctx, perturbations) do
    perturbations
    |> Enum.scan({ctx, []}, fn perturbation, {acc, _emissions} -> Knot.tick(acc, perturbation) end)
    |> Enum.map(fn {stepped, emissions} -> {stepped, emissions} end)
  end

  defp fold(ctx, perturbations) do
    Enum.reduce(perturbations, {ctx, []}, fn perturbation, {acc, emitted} ->
      {stepped, emissions} = Knot.tick(acc, perturbation)
      {stepped, emitted ++ emissions}
    end)
  end
end
