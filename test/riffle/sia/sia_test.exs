defmodule Riffle.SiaTest do
  use ExUnit.Case, async: true

  alias Riffle.Ctx
  alias Riffle.Predicate.Item
  alias Riffle.Sia
  alias Riffle.SiaFixtures

  doctest Riffle.Sia

  # The emission stream a two-stage run produces, in firing order. Pinned as a
  # literal rather than assembled from the pipeline, because the point of the
  # assertion is that the shape of a run is a fixed, readable sequence -- a
  # derivation would reproduce whatever the code did.
  @two_stage_tags [
    :status_changed,
    :input_set,
    :stage_started,
    :stage_progress,
    :stage_completed,
    :stage_started,
    :stage_progress,
    :stage_completed,
    :metadata_set,
    :status_changed,
    :output_produced
  ]

  defp ctx, do: Ctx.new(run_id: "sia-test")
  defp tags(emissions), do: Enum.map(emissions, & &1.__struct__.tag())
  defp field(item, name), do: Map.fetch!(item.fields, name)

  describe "run/4 -- staging" do
    test "invariant: a run stages every loop through the knot, in order" do
      {_ctx, emissions} =
        Sia.run(ctx(), SiaFixtures.staging_pipeline(), SiaFixtures.staging_input())

      assert tags(emissions) == @two_stage_tags
    end

    test "invariant: each stage is named for the loop that produced it" do
      {_ctx, emissions} =
        Sia.run(ctx(), SiaFixtures.staging_pipeline(), SiaFixtures.staging_input())

      started = for %Riffle.Ctx.Emission.StageStarted{stage: stage} <- emissions, do: stage

      assert started == [:sia_fixture_even, :sia_fixture_big]
    end

    test "success: a stageless pipeline emits no stage facts and passes its input through" do
      {ctx, emissions} =
        Sia.run(ctx(), SiaFixtures.stageless_pipeline(), SiaFixtures.staging_input())

      assert tags(emissions) == [
               :status_changed,
               :input_set,
               :metadata_set,
               :status_changed,
               :output_produced
             ]

      assert Enum.map(ctx.output, &field(&1, "n")) == ~w[1 2 3 4 5 6]
    end
  end

  describe "run/4 -- results" do
    test "success: the surviving items are the pinned concrete result" do
      {ctx, _emissions} =
        Sia.run(ctx(), SiaFixtures.staging_pipeline(), SiaFixtures.staging_input())

      assert [%Item{} = survivor] = ctx.output
      assert field(survivor, "n") == "6"
      assert Enum.sort(survivor.tags) == [:sia_fixture_big_n, :sia_fixture_even_n]
      assert ctx.status == :completed
      assert ctx.errors == []
    end

    test "success: the recorded stage counts name every stage and its retained count" do
      {ctx, _emissions} =
        Sia.run(ctx(), SiaFixtures.staging_pipeline(), SiaFixtures.staging_input())

      assert ctx.metadata.stage_counts == [sia_fixture_even: 3, sia_fixture_big: 1]
    end

    test "success: empty input completes with no results and zero counts" do
      {ctx, _emissions} = Sia.run(ctx(), SiaFixtures.staging_pipeline(), [])

      assert ctx.output == []
      assert ctx.status == :completed
      assert ctx.metadata.stage_counts == [sia_fixture_even: 0, sia_fixture_big: 0]
    end

    test "success: input that no stage retains completes with no results, not an error" do
      {ctx, _emissions} =
        Sia.run(ctx(), SiaFixtures.staging_pipeline(), [%{"n" => "1"}, %{"n" => "3"}])

      assert ctx.output == []
      assert ctx.status == :completed
      assert ctx.errors == []
    end
  end

  describe "run/4 -- ingest" do
    test "success: field maps ingest, and the run records the ingested items as its input" do
      {ctx, _emissions} =
        Sia.run(ctx(), SiaFixtures.single_stage_pipeline(), [%{"n" => "2"}])

      assert [%Item{fields: %{"n" => "2"}}] = ctx.input
    end

    test "success: items ingest unchanged, tags and all" do
      tagged = %{"n" => "2"} |> Item.create() |> Item.add_tag(:already_here)

      {ctx, _emissions} = Sia.run(ctx(), SiaFixtures.single_stage_pipeline(), [tagged])

      assert [%Item{tags: [:already_here]}] = ctx.input
      assert [%Item{} = survivor] = ctx.output
      assert Enum.sort(survivor.tags) == [:already_here, :sia_fixture_even_n]
    end

    test "failure: input outside the declared shapes raises naming what arrived" do
      assert_raise ArgumentError, ~r/"not an item"/, fn ->
        Sia.run(ctx(), SiaFixtures.single_stage_pipeline(), ["not an item"])
      end
    end

    test "failure: ingest is eager, so a stageless run still rejects bad input" do
      # A stageless pipeline evaluates no predicate and touches no item. If
      # ingest were lazy, nothing would force the bad element and the run would
      # report success over input it never converted.
      assert_raise ArgumentError, ~r/:bad/, fn ->
        Sia.run(ctx(), SiaFixtures.stageless_pipeline(), [%{"n" => "2"}, :bad])
      end
    end
  end

  describe "metadata_keys/0" do
    test "invariant: the declared key set is exactly what a run records" do
      {_ctx, emissions} =
        Sia.run(ctx(), SiaFixtures.staging_pipeline(), SiaFixtures.staging_input())

      recorded = for %Riffle.Ctx.Emission.MetadataSet{key: key} <- emissions, do: key

      assert Enum.uniq(recorded) == Sia.metadata_keys()
    end
  end
end
