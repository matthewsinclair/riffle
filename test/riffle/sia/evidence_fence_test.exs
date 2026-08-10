defmodule Riffle.Sia.EvidenceFenceTest do
  use ExUnit.Case, async: true

  alias Riffle.Ctx
  alias Riffle.Ctx.Emission
  alias Riffle.Sia
  alias Riffle.SiaFixtures

  # The fence over D2, the defect that started this thread. The source layer
  # computed correct results, materialised them to derive tag counts, threw the
  # results away, and recorded `results_available: true`. The flag was not stale
  # -- it was false the moment it was written, and the characterisation tests
  # read a structural default, so no assertion could see it.
  #
  # Two invariants, checked over every shape a run can take:
  #
  #   1. Results are the same value in all three places they appear.
  #   2. Every derived fact arrives with the evidence for it -- no count and no
  #      recorded statistic survives without the collection it describes.
  #
  # The run matrix is declared rather than sampled: a fence that only ever saw
  # the happy path would pass while every edge lied. Each shape exists because a
  # naive implementation can get it wrong differently -- nothing retained, some
  # retained, everything retained, one stage, no stages at all, no input.

  defp run_matrix do
    [
      {"two stages, some retained", SiaFixtures.staging_pipeline(), SiaFixtures.staging_input()},
      {"two stages, none retained", SiaFixtures.staging_pipeline(), [%{"n" => "1"}]},
      {"two stages, all retained", SiaFixtures.staging_pipeline(), [%{"n" => "6"}]},
      {"two stages, no input", SiaFixtures.staging_pipeline(), []},
      {"one stage", SiaFixtures.single_stage_pipeline(), SiaFixtures.staging_input()},
      {"no stages", SiaFixtures.stageless_pipeline(), SiaFixtures.staging_input()},
      {"no stages, no input", SiaFixtures.stageless_pipeline(), []}
    ]
  end

  defp run(pipeline, input), do: Sia.run(Ctx.new(run_id: "evidence-fence"), pipeline, input)

  test "fence: a completed run's results are the same value in all three places" do
    for {shape, pipeline, input} <- run_matrix() do
      {ctx, emissions} = run(pipeline, input)

      assert ctx.status == :completed, shape

      # Place two: the emission a consumer reads.
      assert [%Emission.OutputProduced{payload: emitted}] =
               for(%Emission.OutputProduced{} = e <- emissions, do: e)

      assert emitted == ctx.output, shape

      # Place three: the last stage's own output. A stageless run has no stage
      # to compare against, and its results are exactly what came in -- pinning
      # that here is what stops "no stages" becoming an unexamined hole.
      assert last_stage_output(emissions, ctx.input) == ctx.output, shape
    end
  end

  test "fence: every derived fact arrives with its evidence" do
    for {shape, pipeline, input} <- run_matrix() do
      {ctx, emissions} = run(pipeline, input)

      progress = for %Emission.StageProgress{} = e <- emissions, do: e
      completed = for %Emission.StageCompleted{} = e <- emissions, do: e

      # Paired by position, never by stage name: two loops may legitimately
      # carry the same name, and pairing by name would silently merge them.
      assert length(progress) == length(completed), shape

      # Distinct bindings, then an assertion: reusing one name across both
      # patterns would pin the second, and a stage-name mismatch would quietly
      # filter the pair out of the comprehension instead of failing.
      for {reported, evidence} <- Enum.zip(progress, completed) do
        assert reported.stage == evidence.stage, shape
        assert reported.progress.retained == length(evidence.output), shape
      end

      # A stage received exactly what the stage before it retained, and the
      # first received the run's input. A count with no collection behind it
      # cannot satisfy this.
      received = Enum.map(progress, & &1.progress.received)
      expected = [length(ctx.input) | Enum.map(completed, &length(&1.output))]

      assert received == Enum.take(expected, length(received)), shape

      # And the one statistic the run records recomputes from those same facts.
      assert recorded_metadata(emissions) == [
               stage_counts: Enum.map(completed, &{&1.stage, length(&1.output)})
             ],
             shape
    end
  end

  test "fence: the run records no metadata key it has not declared" do
    for {shape, pipeline, input} <- run_matrix() do
      {_ctx, emissions} = run(pipeline, input)

      keys = for %Emission.MetadataSet{key: key} <- emissions, do: key

      assert keys -- Sia.metadata_keys() == [], shape
    end
  end

  defp last_stage_output(emissions, fallback) do
    emissions
    |> Enum.reduce(fallback, fn
      %Emission.StageCompleted{output: output}, _previous -> output
      _other, previous -> previous
    end)
  end

  defp recorded_metadata(emissions),
    do: for(%Emission.MetadataSet{key: key, value: value} <- emissions, do: {key, value})
end
