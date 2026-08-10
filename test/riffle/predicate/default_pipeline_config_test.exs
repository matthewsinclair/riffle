defmodule Riffle.Predicate.DefaultPipelineConfigTest do
  use ExUnit.Case, async: true

  alias Riffle.Predicate.Pipeline
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

      # Exhaustive pin: any leaked entry (eg a DSL utility function name)
      # fails, not just the two excluded ones
      assert Enum.sort(pipelines) == [:test_pipeline1, :test_pipeline2]
    end

    test "get_pipeline returns pipeline by atom name" do
      assert %Pipeline{name: :test_pipeline1, description: "Test pipeline 1"} =
               TestPipeline.get_pipeline(:test_pipeline1)
    end

    test "get_pipeline returns pipeline by string name" do
      assert %Pipeline{name: :test_pipeline1} = TestPipeline.get_pipeline("test_pipeline1")
    end

    test "get_pipeline returns nil for non-existent pipeline" do
      assert is_nil(TestPipeline.get_pipeline(:non_existent))
      assert is_nil(TestPipeline.get_pipeline("non_existent"))
    end

    test "get_pipeline returns nil for names that are loops or predicates" do
      assert is_nil(TestPipeline.get_pipeline(:test_loop))
      assert is_nil(TestPipeline.get_pipeline(:test_predicate1))
    end

    test "get_loop returns loop by name" do
      assert %{name: :test_loop, description: "Test loop"} = TestPipeline.get_loop(:test_loop)
    end

    test "get_predicate returns predicate by name" do
      assert %{name: :test_predicate1, description: "Test predicate 1"} =
               TestPipeline.get_predicate(:test_predicate1)
    end
  end
end
