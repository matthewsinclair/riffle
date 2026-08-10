defmodule Riffle.Predicate.RegistryTest do
  # Per-test registry names + per-test tmp_dir fixtures: fully isolated.
  use ExUnit.Case, async: true

  alias Riffle.Predicate.Registry
  alias Riffle.Predicate.Item

  @moduletag :tmp_dir

  defmodule TestPredicates do
    use Riffle.Predicate.Dsl.Macro

    defpredicate :active, "Active users" do
      fn item -> item.fields["status"] == "active" end
    end

    defpredicate :premium do
      fn item -> item.fields["tier"] == "premium" end
    end

    defloop :user_signals, "User signal detection" do
      predicate(:active)
      predicate(:premium)
    end

    defpipeline :user_pipeline, "User processing pipeline" do
      loop(:user_signals)
    end
  end

  setup %{tmp_dir: tmp_dir} do
    # Start a registry for each test with a unique name; the test supervisor
    # owns its lifecycle (no manual stop, no leak on failure).
    registry_name = :"test_registry_#{:erlang.unique_integer([:positive])}"
    start_supervised!({Registry, [name: registry_name]})

    pred_file = Path.join(tmp_dir, "test.pred")

    File.write!(pred_file, """
    predicate(:trial, "Trial users") do
      fn item -> item.fields["tier"] == "trial" end
    end

    loop(:trial_signals, "Trial signals") do
      predicate(:trial)
    end

    pipeline(:trial_pipeline, "Trial pipeline") do
      loop(:trial_signals)
    end
    """)

    {:ok, registry: registry_name, fixtures_dir: tmp_dir, pred_file: pred_file}
  end

  describe "register_module/2" do
    test "registers predicates, loops, and pipelines from a module", %{registry: registry} do
      assert :ok = Registry.register_module(TestPredicates, registry)

      # Check if predicates are registered
      predicates = Registry.list_predicates(registry)
      assert :active in predicates
      assert :premium in predicates

      # Check if loops are registered
      loops = Registry.list_loops(registry)
      assert :user_signals in loops

      # Check if pipelines are registered
      pipelines = Registry.list_pipelines(registry)
      assert :user_pipeline in pipelines
    end

    test "retrieves predicate functions that work correctly", %{registry: registry} do
      Registry.register_module(TestPredicates, registry)

      {:ok, active_pred} = Registry.get_predicate(:active, registry)

      # Test the predicate function
      active_item = Item.create(%{"status" => "active"})
      inactive_item = Item.create(%{"status" => "inactive"})

      assert active_pred.(active_item) == true
      assert active_pred.(inactive_item) == false
    end

    test "retrieves loop instances that work correctly", %{registry: registry} do
      Registry.register_module(TestPredicates, registry)

      {:ok, user_signals} = Registry.get_loop(:user_signals, registry)
      assert user_signals.name == :user_signals

      active_item = Item.create(%{"status" => "active", "tier" => "basic"})
      premium_item = Item.create(%{"status" => "active", "tier" => "premium"})
      inactive_item = Item.create(%{"status" => "inactive", "tier" => "basic"})

      filtered =
        user_signals
        |> Riffle.Predicate.Loop.filter([active_item, premium_item, inactive_item])
        |> Enum.to_list()

      assert [
               %Item{fields: %{"tier" => "basic"}, tags: [:active]},
               %Item{fields: %{"tier" => "premium"}, tags: [:premium, :active]}
             ] = filtered
    end

    test "returns error for non-existent module", %{registry: registry} do
      assert {:error, {:module_registration_error, NonExistentModule, _}} =
               Registry.register_module(NonExistentModule, registry)
    end
  end

  describe "load_file/2" do
    test "loads predicates, loops, and pipelines from a file", %{
      registry: registry,
      pred_file: pred_file
    } do
      assert :ok = Registry.load_file(pred_file, registry)

      # Check if predicates are registered
      predicates = Registry.list_predicates(registry)
      assert :trial in predicates

      # Check if loops are registered
      loops = Registry.list_loops(registry)
      assert :trial_signals in loops

      # Check if pipelines are registered
      pipelines = Registry.list_pipelines(registry)
      assert :trial_pipeline in pipelines
    end

    test "retrieves predicate functions that work correctly", %{
      registry: registry,
      pred_file: pred_file
    } do
      Registry.load_file(pred_file, registry)

      {:ok, trial_pred} = Registry.get_predicate(:trial, registry)

      # Test the predicate function
      trial_item = Item.create(%{"tier" => "trial"})
      premium_item = Item.create(%{"tier" => "premium"})

      assert trial_pred.(trial_item) == true
      assert trial_pred.(premium_item) == false
    end

    test "returns error for non-existent file", %{registry: registry} do
      assert {:error, {:file_load_error, "nonexistent.pred", _}} =
               Registry.load_file("nonexistent.pred", registry)
    end
  end

  describe "load_directory/3" do
    test "loads all files in directory", %{registry: registry, fixtures_dir: fixtures_dir} do
      # Create another test file in a subdirectory
      File.mkdir_p!(Path.join(fixtures_dir, "subdir"))

      File.write!(Path.join(fixtures_dir, "subdir/premium.pred"), """
      predicate(:premium_plus, "Premium Plus users") do
        fn item -> item.fields["tier"] == "premium_plus" end
      end

      loop(:premium_plus_signals, "Premium Plus signals") do
        predicate(:premium_plus)
      end

      pipeline(:premium_plus_pipeline, "Premium Plus pipeline") do
        loop(:premium_plus_signals)
      end
      """)

      # Need to pass true for recursive parameter
      assert :ok = Registry.load_directory(fixtures_dir, true, registry)

      # Check if predicates are registered
      predicates = Registry.list_predicates(registry)
      assert :trial in predicates
      assert :premium_plus in predicates

      # Check if loops are registered
      loops = Registry.list_loops(registry)
      assert :trial_signals in loops
      assert :premium_plus_signals in loops

      # Check if pipelines are registered
      pipelines = Registry.list_pipelines(registry)
      assert :trial_pipeline in pipelines
      assert :premium_plus_pipeline in pipelines
    end
  end

  describe "get_* functions" do
    test "get_predicate returns :error for non-existent predicate", %{registry: registry} do
      assert {:error, {:not_found, :predicate, :nonexistent}} =
               Registry.get_predicate(:nonexistent, registry)
    end

    test "get_loop returns :error for non-existent loop", %{registry: registry} do
      assert {:error, {:not_found, :loop, :nonexistent}} =
               Registry.get_loop(:nonexistent, registry)
    end

    test "get_pipeline returns :error for non-existent pipeline", %{registry: registry} do
      assert {:error, {:not_found, :pipeline, :nonexistent}} =
               Registry.get_pipeline(:nonexistent, registry)
    end
  end

  describe "clear/1" do
    test "removes all registered entities", %{registry: registry, pred_file: pred_file} do
      # Register a module and load a file
      Registry.register_module(TestPredicates, registry)
      Registry.load_file(pred_file, registry)

      # Verify entities are registered
      assert Registry.list_predicates(registry) != []
      assert Registry.list_loops(registry) != []
      assert Registry.list_pipelines(registry) != []

      # Clear the registry
      Registry.clear(registry)

      # Verify registry is empty
      assert Registry.list_predicates(registry) == []
      assert Registry.list_loops(registry) == []
      assert Registry.list_pipelines(registry) == []
    end
  end

  describe "integration" do
    test "combines entities from different sources", %{registry: registry, pred_file: pred_file} do
      # Register from module and load from file
      Registry.register_module(TestPredicates, registry)
      Registry.load_file(pred_file, registry)

      # Access entities from both sources
      {:ok, active_pred} = Registry.get_predicate(:active, registry)
      {:ok, trial_pred} = Registry.get_predicate(:trial, registry)
      {:ok, user_pipeline} = Registry.get_pipeline(:user_pipeline, registry)
      {:ok, trial_pipeline} = Registry.get_pipeline(:trial_pipeline, registry)

      # Test functionality
      assert active_pred.(Item.create(%{"status" => "active"})) == true
      assert trial_pred.(Item.create(%{"tier" => "trial"})) == true
      assert user_pipeline.name == :user_pipeline
      assert trial_pipeline.name == :trial_pipeline
    end
  end
end
