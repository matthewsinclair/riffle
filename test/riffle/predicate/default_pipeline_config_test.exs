defmodule Riffle.Predicate.DefaultPipelineConfigTest do
  use ExUnit.Case, async: true

  alias Riffle.Predicate.PipelineConfig

  # Define a test module that uses DefaultPipelineConfig
  defmodule TestPipeline do
    use Riffle.Predicate.Dsl.Macro
    use Riffle.Predicate.DefaultPipelineConfig

    # Define some test predicates
    defpredicate :test_predicate1, "Test predicate 1" do
      expr(true)
    end

    defpredicate :test_predicate2, "Test predicate 2" do
      expr(false)
    end

    # Define a test loop
    defloop :test_loop, "Test loop" do
      predicate(:test_predicate1)
      predicate(:test_predicate2)
    end

    # Define test pipelines
    defpipeline :test_pipeline1, "Test pipeline 1" do
      loop(:test_loop)
    end

    defpipeline :test_pipeline2, "Test pipeline 2" do
      loop(:test_loop)
    end
  end

  describe "DefaultPipelineConfig" do
    test "implements PipelineConfig behaviour" do
      # Verify implementation
      assert Kernel.function_exported?(TestPipeline, :get_pipeline, 1)
      assert Kernel.function_exported?(TestPipeline, :get_loop, 1)
      assert Kernel.function_exported?(TestPipeline, :get_predicate, 1)
      assert Kernel.function_exported?(TestPipeline, :list_pipelines, 0)

      behaviours = TestPipeline.__info__(:attributes)[:behaviour]
      assert PipelineConfig in behaviours
    end

    test "list_pipelines returns all pipelines" do
      pipelines = TestPipeline.list_pipelines()

      assert is_list(pipelines)
      assert :test_pipeline1 in pipelines
      assert :test_pipeline2 in pipelines

      # Ensure DSL utility functions are not included
      assert :predicates not in pipelines
      assert :loops not in pipelines
    end

    test "get_pipeline returns pipeline by atom name" do
      pipeline = TestPipeline.get_pipeline(:test_pipeline1)

      assert is_map(pipeline)
      assert pipeline.name == :test_pipeline1
      assert pipeline.description == "Test pipeline 1"
    end

    test "get_pipeline returns pipeline by string name" do
      pipeline = TestPipeline.get_pipeline("test_pipeline1")

      assert is_map(pipeline)
      assert pipeline.name == :test_pipeline1
    end

    test "get_pipeline returns nil for non-existent pipeline" do
      assert is_nil(TestPipeline.get_pipeline(:non_existent))
      assert is_nil(TestPipeline.get_pipeline("non_existent"))
    end

    test "get_loop returns loop by name" do
      loop = TestPipeline.get_loop(:test_loop)

      assert is_map(loop)
      assert loop.name == :test_loop
      assert loop.description == "Test loop"
    end

    test "get_predicate returns predicate by name" do
      predicate = TestPipeline.get_predicate(:test_predicate1)

      assert is_map(predicate)
      assert predicate.name == :test_predicate1
      assert predicate.description == "Test predicate 1"
    end
  end
end
