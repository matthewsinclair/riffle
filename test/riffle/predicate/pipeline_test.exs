defmodule Riffle.Predicate.PipelineTest do
  use ExUnit.Case, async: true
  doctest Riffle.Predicate.Pipeline

  alias Riffle.Predicate
  alias Riffle.Predicate.Loop
  alias Riffle.Predicate.Pipeline
  alias Riffle.Predicate.Item

  describe "new/3" do
    test "creates a new pipeline definition" do
      loop = Loop.new(:test_loop, "Test loop", [])
      pipeline = Pipeline.new(:test_pipeline, "Test pipeline", [loop])
      assert pipeline.name == :test_pipeline
      assert pipeline.description == "Test pipeline"
      assert pipeline.loops == [loop]
    end
  end

  describe "process/2" do
    setup do
      loop1 =
        Loop.new(:active, "Active users", [
          Predicate.new(:active, "Active", fn item -> item.fields["status"] == "active" end)
        ])

      loop2 =
        Loop.new(:premium, "Premium users", [
          Predicate.new(:premium, "Premium", fn item -> item.fields["tier"] == "premium" end)
        ])

      pipeline = Pipeline.new(:test_pipeline, "Test pipeline", [loop1, loop2])

      items = [
        Item.new(["status", "tier"], ["active", "premium"]),
        Item.new(["status", "tier"], ["active", "basic"]),
        Item.new(["status", "tier"], ["inactive", "premium"]),
        Item.new(["status", "tier"], ["inactive", "basic"])
      ]

      {:ok, pipeline: pipeline, items: items}
    end

    test "filters items through all loops", %{pipeline: pipeline, items: items} do
      processed = pipeline |> Pipeline.process(items) |> Enum.to_list()
      assert length(processed) == 1

      item = List.first(processed)
      assert item.fields["status"] == "active"
      assert item.fields["tier"] == "premium"
      assert Enum.sort(item.tags) == [:active, :premium]
    end

    test "returns empty list when no items pass all loops", %{pipeline: pipeline} do
      items = [Item.new(["status", "tier"], ["inactive", "basic"])]
      processed = pipeline |> Pipeline.process(items) |> Enum.to_list()
      assert processed == []
    end
  end

  describe "process_csv/3" do
    test "processes CSV records through the pipeline" do
      loop =
        Loop.new(:active, "Active users", [
          Predicate.new(:active, "Active", fn item -> item.fields["status"] == "active" end)
        ])

      pipeline = Pipeline.new(:test_pipeline, "Test pipeline", [loop])

      header = ["id", "status"]

      records = [
        ["1", "active"],
        ["2", "inactive"]
      ]

      processed = pipeline |> Pipeline.process_csv(header, records) |> Enum.to_list()
      assert length(processed) == 1
      assert List.first(processed).fields["id"] == "1"
      assert List.first(processed).tags == [:active]
    end
  end

  describe "add_loop/2" do
    test "adds a loop to a pipeline" do
      pipeline = Pipeline.new(:test_pipeline, "Test pipeline", [])
      loop = Loop.new(:test_loop, "Test loop", [])
      updated_pipeline = Pipeline.add_loop(pipeline, loop)
      assert length(updated_pipeline.loops) == 1
      assert hd(updated_pipeline.loops).name == :test_loop
    end
  end
end
