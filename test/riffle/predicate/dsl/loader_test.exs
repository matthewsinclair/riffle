defmodule Riffle.Predicate.Dsl.LoaderTest do
  # Per-test tmp_dir fixtures: no shared mutable paths, safe async.
  use ExUnit.Case, async: true

  alias Riffle.Predicate.Dsl.Loader

  @moduletag :tmp_dir

  setup %{tmp_dir: tmp_dir} do
    File.write!(Path.join(tmp_dir, "basic.pred"), """
    predicate(:active, "Active users") do
      fn item -> item.fields["status"] == "active" end
    end

    predicate(:premium, "Premium users") do
      fn item -> item.fields["tier"] == "premium" end
    end

    loop(:user_signals, "User signal detection") do
      predicate(:active)
      predicate(:premium)
    end

    pipeline(:user_pipeline, "User processing pipeline") do
      loop(:user_signals)
    end
    """)

    File.mkdir_p!(Path.join(tmp_dir, "nested"))

    File.write!(Path.join(tmp_dir, "nested/trial.pred"), """
    predicate(:trial, "Trial users") do
      fn item -> item.fields["tier"] == "trial" end
    end

    loop(:trial_signals) do
      predicate(:trial)
    end

    pipeline(:trial_pipeline) do
      loop(:trial_signals)
    end
    """)

    File.write!(Path.join(tmp_dir, "complex.pred"), """
    pipeline(:complex_pipeline, "Complex processing pipeline") do
      loop(:signal_detection, "Signal detection loop") do
        predicate(:active)

        predicate(:new_user, "New user detection") do
          fn item ->
            created_at = item.fields["created_at"]
            now = DateTime.utc_now() |> DateTime.to_unix()
            created_unix = DateTime.from_iso8601(created_at)
                        |> elem(1)
                        |> DateTime.to_unix()
            now - created_unix < 86400 * 30 # Less than 30 days
          end
        end
      end

      loop(:trial_signals)
    end
    """)

    {:ok, fixtures_dir: tmp_dir}
  end

  describe "load_file/1" do
    test "loads predicates, loops, and pipelines from a file", %{fixtures_dir: fixtures_dir} do
      {:ok, definitions} = Loader.load_file(Path.join(fixtures_dir, "basic.pred"))

      assert length(definitions.predicates) == 2
      assert length(definitions.loops) == 1
      assert length(definitions.pipelines) == 1

      # Check predicate details
      active_pred = Enum.find(definitions.predicates, &(&1.name == :active))
      assert active_pred.description == "Active users"
      assert match?({:fn, _, _}, active_pred.body)

      # Check loop details
      user_signals = Enum.find(definitions.loops, &(&1.name == :user_signals))
      assert user_signals.description == "User signal detection"
      assert length(user_signals.predicates) == 2

      # Check pipeline details
      user_pipeline = Enum.find(definitions.pipelines, &(&1.name == :user_pipeline))
      assert user_pipeline.description == "User processing pipeline"
      assert length(user_pipeline.loops) == 1
    end

    test "returns error for non-existent file" do
      assert {:error, {:file_load_error, "nonexistent.pred", _}} =
               Loader.load_file("nonexistent.pred")
    end

    test "returns error for invalid syntax", %{fixtures_dir: fixtures_dir} do
      # Create a file with invalid syntax
      invalid_file = Path.join(fixtures_dir, "invalid.pred")
      File.write!(invalid_file, "invalid { syntax")

      assert {:error, {:file_load_error, ^invalid_file, _}} = Loader.load_file(invalid_file)
    end
  end

  describe "load_directory/2" do
    test "loads all files in directory non-recursively", %{fixtures_dir: fixtures_dir} do
      {:ok, definitions} = Loader.load_directory(fixtures_dir, false)

      assert length(definitions.predicates) == 2
      assert length(definitions.loops) == 1
      # One from basic.pred, one from complex.pred
      assert length(definitions.pipelines) == 2

      # Should not include trial.pred which is in nested/
      assert Enum.all?(definitions.predicates, &(&1.name != :trial))
    end

    test "loads all files recursively (default)", %{fixtures_dir: fixtures_dir} do
      {:ok, definitions} = Loader.load_directory(fixtures_dir)

      # active, premium, trial
      assert length(definitions.predicates) == 3
      # user_signals, trial_signals
      assert length(definitions.loops) == 2
      # user_pipeline, trial_pipeline, complex_pipeline
      assert length(definitions.pipelines) == 3

      # Should include trial.pred from nested/
      assert Enum.any?(definitions.predicates, &(&1.name == :trial))
    end

    test "returns error when no files found" do
      assert {:error, {:no_files_found, _}} = Loader.load_directory("nonexistent_dir")
    end
  end

  describe "create_instances/1" do
    test "creates runtime instances from definitions", %{fixtures_dir: fixtures_dir} do
      {:ok, definitions} = Loader.load_directory(fixtures_dir)
      {:ok, instances} = Loader.create_instances(definitions)

      # Check predicates
      assert Map.has_key?(instances.predicates, :active)
      assert Map.has_key?(instances.predicates, :premium)
      assert Map.has_key?(instances.predicates, :trial)

      # Check loops
      assert Map.has_key?(instances.loops, :user_signals)
      assert Map.has_key?(instances.loops, :trial_signals)

      # Check pipelines
      assert Map.has_key?(instances.pipelines, :user_pipeline)
      assert Map.has_key?(instances.pipelines, :trial_pipeline)
      assert Map.has_key?(instances.pipelines, :complex_pipeline)

      # Test an actual predicate
      active_pred = instances.predicates.active
      active_item = Riffle.Predicate.Item.create(%{"status" => "active"})
      inactive_item = Riffle.Predicate.Item.create(%{"status" => "inactive"})

      {matched, _} = Riffle.Predicate.evaluate(active_pred, active_item)
      assert matched == true

      {matched, _} = Riffle.Predicate.evaluate(active_pred, inactive_item)
      assert matched == false

      # Test pipeline with pipeline
      pipeline = instances.pipelines.user_pipeline
      items = [active_item, inactive_item]
      filtered = Riffle.Predicate.Pipeline.process(pipeline, items) |> Enum.to_list()

      assert length(filtered) == 1
      assert hd(filtered).fields == active_item.fields
    end

    test "handles inline definitions alongside cross-file references", %{
      fixtures_dir: fixtures_dir
    } do
      {:ok, definitions} = Loader.load_directory(fixtures_dir)
      {:ok, instances} = Loader.create_instances(definitions)

      # The complex pipeline mixes an inline loop (holding a reference to
      # basic.pred's :active plus an inline :new_user definition) with a
      # reference to nested/trial.pred's :trial_signals loop. Every leaf must
      # come back runnable -- no nil entries, no unresolved refs.
      assert %Riffle.Predicate.Pipeline{
               name: :complex_pipeline,
               description: "Complex processing pipeline",
               loops: [
                 %Riffle.Predicate.Loop{
                   name: :signal_detection,
                   predicates: [%{name: :active}, %{name: :new_user}]
                 },
                 %Riffle.Predicate.Loop{
                   name: :trial_signals,
                   predicates: [%{name: :trial}]
                 }
               ]
             } = instances.pipelines.complex_pipeline

      assert Enum.all?(
               hd(instances.pipelines.complex_pipeline.loops).predicates,
               &is_function(&1.function, 1)
             )
    end

    test "success: the injected STD alias resolves in DSL strings" do
      dsl_content = """
      predicate(:active_user, "Active users") do
        call &STD.Boolean.is_true/1, ["active"]
      end
      """

      {:ok, %{predicates: [pred_def]}} = Loader.load_string(dsl_content)
      assert pred_def.name == :active_user
      assert pred_def.description == "Active users"
    end

    test "success: both the STD alias and the full StandardLib path parse in DSL strings" do
      dsl_content = """
      predicate(:active_with_short, "Active users (short syntax)") do
        call &STD.Boolean.is_true/1, ["active"]
      end

      predicate(:active_with_long, "Active users (long syntax)") do
        call &Riffle.Predicate.StandardLib.Boolean.is_true/1, ["active"]
      end
      """

      {:ok, %{predicates: pred_defs}} = Loader.load_string(dsl_content)

      assert [%{name: :active_with_short}, %{name: :active_with_long}] = pred_defs
    end

    test "failure: an unresolved reference in a .pred file is a tagged error, never a nil entry",
         %{fixtures_dir: fixtures_dir} do
      broken = Path.join(fixtures_dir, "broken.pred")

      File.write!(broken, """
      loop(:broken_loop, "References a predicate that does not exist") do
        predicate(:does_not_exist)
      end
      """)

      {:ok, definitions} = Loader.load_file(broken)

      assert Loader.create_instances(definitions) ==
               {:error, {:unresolved, :predicate, :does_not_exist, :definitions}}
    end
  end

  describe "load_string/1 in-block junk" do
    test "failure: junk inside a loop block is a tagged invalid_dsl error" do
      dsl_content = """
      loop(:sloppy, "Loop with a typo statement") do
        predicate(:active)
        predicat(:premium)
      end
      """

      assert {:error, {:invalid_dsl, message}} = Loader.load_string(dsl_content)
      assert message =~ "unrecognised statement in a loop block"
      assert message =~ "predicat(:premium)"
    end

    test "failure: junk inside a pipeline block is a tagged invalid_dsl error" do
      dsl_content = """
      pipeline(:sloppy_pipeline, "Pipeline with a typo statement") do
        loop(:user_signals)
        lop(:trial_signals)
      end
      """

      assert {:error, {:invalid_dsl, message}} = Loader.load_string(dsl_content)
      assert message =~ "unrecognised statement in a pipeline block"
      assert message =~ "lop(:trial_signals)"
    end
  end
end
