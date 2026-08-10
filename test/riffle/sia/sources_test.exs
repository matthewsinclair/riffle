defmodule Riffle.Sia.SourcesTest do
  # Mutates the :riffle application environment and the global evaluation
  # cache -- cannot run async.
  use ExUnit.Case, async: false

  alias Riffle.CacheHelpers
  alias Riffle.Ctx
  alias Riffle.Predicate.Pipeline
  alias Riffle.Sia
  alias Riffle.Sia.DefaultPipeline
  alias Riffle.Sia.Pipelines
  alias Riffle.SiaFixtures

  setup do
    original = Application.fetch_env(:riffle, :default_pipeline)

    on_exit(fn ->
      case original do
        {:ok, value} -> Application.put_env(:riffle, :default_pipeline, value)
        :error -> Application.delete_env(:riffle, :default_pipeline)
      end
    end)

    :ok
  end

  describe "fetch/2 -- the closed vocabulary" do
    test "success: a struct source is the pipeline, named or not" do
      pipeline = SiaFixtures.staging_pipeline()

      assert {:ok, ^pipeline} = Pipelines.fetch(pipeline, nil)
      assert {:ok, ^pipeline} = Pipelines.fetch(pipeline, :sia_fixture_staging)
    end

    test "failure: asking a struct source for a different pipeline is a contradiction" do
      assert_raise ArgumentError, ~r/:somewhere_else.*:sia_fixture_staging/, fn ->
        Pipelines.fetch(SiaFixtures.staging_pipeline(), :somewhere_else)
      end
    end

    test "success: a module source resolves a named pipeline to a hydrated struct" do
      assert {:ok, %Pipeline{name: :sense_pipeline, loops: [loop]}} =
               Pipelines.fetch({:module, DefaultPipeline}, :sense_pipeline)

      assert loop.name == :signal_loop
    end

    test "success: a file source resolves a named pipeline to a hydrated struct" do
      assert {:ok, %Pipeline{name: :infer_pipeline, loops: loops}} =
               Pipelines.fetch({:file, DefaultPipeline.pred_path()}, :infer_pipeline)

      assert Enum.map(loops, & &1.name) == [:signal_loop, :inference_loop]
    end

    test "success: a named source with no name given takes the default pipeline" do
      assert Pipelines.default_name() == :main
      assert {:ok, %Pipeline{name: :main}} = Pipelines.fetch({:module, DefaultPipeline}, nil)
    end

    test "success: :default_module reads the configured module" do
      Application.put_env(:riffle, :default_pipeline, DefaultPipeline)

      assert {:ok, %Pipeline{name: :main}} = Pipelines.fetch(:default_module, nil)
    end

    test "failure: :default_module with nothing configured is a tagged error, not a crash" do
      Application.delete_env(:riffle, :default_pipeline)

      assert Pipelines.fetch(:default_module, nil) == {:error, :no_default_pipeline_module}
    end

    test "failure: a source outside the vocabulary raises naming what arrived" do
      assert_raise ArgumentError, ~r/"predicates\.pred" is not a pipeline source/, fn ->
        Pipelines.fetch("predicates.pred", :main)
      end
    end

    test "failure: an unresolvable source fails the run rather than raising out of it" do
      Application.put_env(:riffle, :default_pipeline, DefaultPipeline)

      {ctx, _emissions} =
        Sia.run(Ctx.new(run_id: "sources"), :default_module, [], pipeline: :no_such_pipeline)

      assert ctx.status == :failed
    end

    test "failure: an option the run does not take is a loud error, not a silent ignore" do
      assert_raise ArgumentError, ~r/:pipelines/, fn ->
        Sia.run(Ctx.new(run_id: "sources"), SiaFixtures.staging_pipeline(), [], pipelines: :main)
      end
    end
  end

  describe "the file and the module carry the same definitions" do
    setup do
      # With the cache on, both sources answer from one entry -- the key is the
      # predicate's name and the item, and the two sources share every name. So
      # the second run would return the first run's answers and the comparison
      # below would hold however far the two definitions had drifted.
      CacheHelpers.reset_cache(enabled: false)

      on_exit(fn -> CacheHelpers.reset_cache() end)

      :ok
    end

    test "invariant: the file source and the module source produce identical results" do
      for name <- [:main, :infer_pipeline, :sense_pipeline] do
        {from_file, _emissions} = run({:file, DefaultPipeline.pred_path()}, name)
        {from_module, _emissions} = run({:module, DefaultPipeline}, name)

        assert from_file.output == from_module.output
        assert from_file.metadata.stage_counts == from_module.metadata.stage_counts
      end
    end

    test "invariant: the two sources declare the same pipelines and the same stages" do
      {:ok, definitions} = Riffle.Predicate.Dsl.Loader.load_file(DefaultPipeline.pred_path())
      {:ok, instances} = Riffle.Predicate.Dsl.Loader.create_instances(definitions)

      from_file = instances.pipelines |> Map.keys() |> Enum.sort()
      from_module = DefaultPipeline.list_pipelines() |> Enum.sort()

      assert from_file == from_module
      assert from_file == [:infer_pipeline, :main, :sense_pipeline]

      for name <- from_file do
        {:ok, file_pipeline} = Pipelines.fetch({:file, DefaultPipeline.pred_path()}, name)
        {:ok, module_pipeline} = Pipelines.fetch({:module, DefaultPipeline}, name)

        assert Enum.map(file_pipeline.loops, & &1.name) ==
                 Enum.map(module_pipeline.loops, & &1.name)
      end
    end
  end

  defp run(source, name) do
    Sia.run(
      Ctx.new(run_id: "sources"),
      source,
      SiaFixtures.characterisation_input(),
      pipeline: name
    )
  end
end
