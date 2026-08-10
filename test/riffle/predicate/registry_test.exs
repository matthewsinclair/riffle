defmodule Riffle.Predicate.RegistryTest do
  # Per-test registry names + per-test tmp_dir fixtures: fully isolated.
  use ExUnit.Case, async: true

  alias Riffle.DslFixtures.UserPredicates
  alias Riffle.Predicate.Item
  alias Riffle.Predicate.Registry

  @moduletag :tmp_dir

  setup %{tmp_dir: tmp_dir} do
    # Start a registry for each test with a unique name; the test supervisor
    # owns its lifecycle (no manual stop, no leak on failure).
    registry_name = :"test_registry_#{:erlang.unique_integer([:positive])}"
    start_supervised!({Registry, [name: registry_name]})

    pred_file = Path.join(tmp_dir, "test.pred")
    File.write!(pred_file, Riffle.DslFixtures.trial_source())

    {:ok, registry: registry_name, fixtures_dir: tmp_dir, pred_file: pred_file}
  end

  describe "register_module/2" do
    test "registers predicates, loops, and pipelines from a module", %{registry: registry} do
      assert :ok = Registry.register_module(UserPredicates, registry)

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

    test "retrieves hydrated predicate definitions that evaluate correctly", %{
      registry: registry
    } do
      Registry.register_module(UserPredicates, registry)

      {:ok, active_pred} = Registry.get_predicate(:active, registry)

      active_item = Item.create(%{"status" => "active"})
      inactive_item = Item.create(%{"status" => "inactive"})

      assert {true, %Item{tags: [:active]}} = Riffle.Predicate.evaluate(active_pred, active_item)
      assert {false, %Item{tags: []}} = Riffle.Predicate.evaluate(active_pred, inactive_item)
    end

    test "retrieves loop instances that work correctly", %{registry: registry} do
      Registry.register_module(UserPredicates, registry)

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

    test "retrieves hydrated predicate definitions that evaluate correctly", %{
      registry: registry,
      pred_file: pred_file
    } do
      Registry.load_file(pred_file, registry)

      {:ok, trial_pred} = Registry.get_predicate(:trial, registry)

      trial_item = Item.create(%{"tier" => "trial"})
      premium_item = Item.create(%{"tier" => "premium"})

      assert {true, %Item{tags: [:trial]}} = Riffle.Predicate.evaluate(trial_pred, trial_item)
      assert {false, %Item{tags: []}} = Riffle.Predicate.evaluate(trial_pred, premium_item)
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
      assert {:error, {:unresolved, :predicate, :nonexistent, :definitions}} =
               Registry.get_predicate(:nonexistent, registry)
    end

    test "get_loop returns :error for non-existent loop", %{registry: registry} do
      assert {:error, {:unresolved, :loop, :nonexistent, :definitions}} =
               Registry.get_loop(:nonexistent, registry)
    end

    test "get_pipeline returns :error for non-existent pipeline", %{registry: registry} do
      assert {:error, {:unresolved, :pipeline, :nonexistent, :definitions}} =
               Registry.get_pipeline(:nonexistent, registry)
    end
  end

  describe "clear/1" do
    test "removes all registered entities", %{registry: registry, pred_file: pred_file} do
      # Register a module and load a file
      Registry.register_module(UserPredicates, registry)
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
      Registry.register_module(UserPredicates, registry)
      Registry.load_file(pred_file, registry)

      # Access entities from both sources
      {:ok, active_pred} = Registry.get_predicate(:active, registry)
      {:ok, trial_pred} = Registry.get_predicate(:trial, registry)
      {:ok, user_pipeline} = Registry.get_pipeline(:user_pipeline, registry)
      {:ok, trial_pipeline} = Registry.get_pipeline(:trial_pipeline, registry)

      # Test functionality
      assert {true, %Item{tags: [:active]}} =
               Riffle.Predicate.evaluate(active_pred, Item.create(%{"status" => "active"}))

      assert {true, %Item{tags: [:trial]}} =
               Riffle.Predicate.evaluate(trial_pred, Item.create(%{"tier" => "trial"}))

      assert user_pipeline.name == :user_pipeline
      assert trial_pipeline.name == :trial_pipeline
    end
  end
end
