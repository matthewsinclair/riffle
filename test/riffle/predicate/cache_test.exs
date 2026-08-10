defmodule Riffle.Predicate.CacheTest do
  # Exercises the global named Cache GenServer -- cannot run async.
  use ExUnit.Case, async: false

  alias Riffle.Predicate.Cache
  alias Riffle.Predicate.Item

  setup do
    # Clear the cache before each test
    :ok = Cache.clear()

    # Configure with default settings
    {:ok, _} = Cache.configure(enabled: true, max_size: 10_000, ttl: 3600)

    # Create a test item
    item = Item.new(["status", "tier"], ["active", "premium"])

    # Return the item for use in tests
    %{item: item}
  end

  describe "cache operations" do
    test "basic cache operations", %{item: item} do
      # Initially empty
      assert {:error, :not_found} = Cache.get(:test_pred, item)

      # Put a value
      assert :ok = Cache.put(:test_pred, item, {true, item})

      # Get the value back
      assert {:ok, {true, ^item}} = Cache.get(:test_pred, item)

      # Clear the cache
      assert :ok = Cache.clear()

      # Should be empty again
      assert {:error, :not_found} = Cache.get(:test_pred, item)
    end

    test "cache expiration", %{item: item} do
      # Set TTL to 1 second for this test
      {:ok, _} = Cache.configure(ttl: 1)

      # Put a value
      :ok = Cache.put(:test_pred, item, {true, item})

      # Should be available immediately
      assert {:ok, {true, ^item}} = Cache.get(:test_pred, item)

      # Wait for expiration
      :timer.sleep(1100)

      # Should be expired now
      assert {:error, :not_found} = Cache.get(:test_pred, item)
    end

    test "cache statistics", %{item: item} do
      :ok = Cache.reset_stats()

      # Start with empty stats
      initial_stats = Cache.stats()
      assert initial_stats.hits == 0
      assert initial_stats.misses == 0

      # Generate a miss
      {:error, :not_found} = Cache.get(:test_pred, item)

      # Should increment misses
      miss_stats = Cache.stats()
      assert miss_stats.misses == 1
      assert miss_stats.hits == 0

      # Put a value
      :ok = Cache.put(:test_pred, item, {true, item})

      # Generate a hit
      {:ok, _} = Cache.get(:test_pred, item)

      # Should increment hits
      hit_stats = Cache.stats()
      assert hit_stats.hits == 1
      assert hit_stats.misses == 1
    end

    test "cache disabling", %{item: item} do
      # Put a value with cache enabled
      :ok = Cache.put(:test_pred, item, {true, item})

      # Verify it's there
      assert {:ok, {true, ^item}} = Cache.get(:test_pred, item)

      # Disable the cache
      {:ok, config} = Cache.configure(enabled: false)
      assert config.enabled == false

      # Shouldn't be able to get or put values now
      assert {:error, :disabled} = Cache.get(:test_pred, item)
      assert {:error, :disabled} = Cache.put(:test_pred, item, {false, item})

      # Re-enable the cache
      {:ok, config} = Cache.configure(enabled: true)
      assert config.enabled == true

      # Original value should still be there if TTL hasn't expired
      assert {:ok, {true, ^item}} = Cache.get(:test_pred, item)
    end

    test "max size enforcement", %{item: item} do
      # Set a very small max size for testing
      {:ok, _} = Cache.configure(max_size: 3)

      # Add multiple items to exceed the cache size
      :ok = Cache.put(:pred1, item, {true, item})
      :ok = Cache.put(:pred2, item, {true, item})
      :ok = Cache.put(:pred3, item, {true, item})

      # Cache should have 3 items now
      stats = Cache.stats()
      assert stats.size == 3

      # Add one more entry to trigger eviction
      :ok = Cache.put(:pred4, item, {true, item})

      # Size should still be 3 due to eviction
      stats = Cache.stats()
      assert stats.size == 3

      # At least one of our previously cached values should be gone
      # (We can't determine which one specifically due to the random eviction policy)
      missing_count =
        Enum.count(
          [:pred1, :pred2, :pred3],
          fn pred -> match?({:error, :not_found}, Cache.get(pred, item)) end
        )

      assert missing_count >= 1

      # The newly added entry should be present though
      assert {:ok, {true, ^item}} = Cache.get(:pred4, item)
    end

    test "different items with same predicate have different cache entries", %{item: item} do
      # Create a second item with different values
      item2 = Item.new(["status", "tier"], ["inactive", "basic"])

      # Put values for both items
      :ok = Cache.put(:test_pred, item, {true, item})
      :ok = Cache.put(:test_pred, item2, {false, item2})

      # Get values back - should be different
      assert {:ok, {true, ^item}} = Cache.get(:test_pred, item)
      assert {:ok, {false, ^item2}} = Cache.get(:test_pred, item2)
    end

    test "config validation" do
      # Valid configurations
      assert {:ok, _} = Cache.configure(enabled: true)
      assert {:ok, _} = Cache.configure(enabled: false)
      assert {:ok, _} = Cache.configure(max_size: 1)
      assert {:ok, _} = Cache.configure(max_size: 1_000_000)
      assert {:ok, _} = Cache.configure(ttl: 0)
      assert {:ok, _} = Cache.configure(ttl: 86400)

      # Invalid configurations
      assert {:error, {:invalid_enabled, "true"}} = Cache.configure(enabled: "true")
      assert {:error, {:invalid_max_size, 0}} = Cache.configure(max_size: 0)
      assert {:error, {:invalid_max_size, -1}} = Cache.configure(max_size: -1)
      assert {:error, {:invalid_ttl, -1}} = Cache.configure(ttl: -1)
    end
  end
end
