defmodule Riffle.Predicate.CacheIntegrationTest do
  # Exercises the global named Cache GenServer -- cannot run async.
  use ExUnit.Case, async: false

  alias Riffle.Predicate
  alias Riffle.Predicate.Item

  setup do
    :ok = Riffle.CacheHelpers.reset_cache()

    # A spy predicate that counts how many times it is evaluated
    counter = :counters.new(1, [:atomics])

    predicate =
      Riffle.CacheHelpers.spy_predicate(
        :test_cached,
        counter,
        1,
        &(&1.fields["status"] == "active")
      )

    item = Item.new(["status"], ["active"])

    # Return test setup
    %{
      predicate: predicate,
      item: item,
      counter: counter
    }
  end

  describe "predicate caching integration" do
    test "cache hits reduce evaluation count", %{
      predicate: predicate,
      item: item,
      counter: counter
    } do
      # First evaluation should always run the predicate
      {true, _updated_item} = Predicate.evaluate(predicate, item)
      assert :counters.get(counter, 1) == 1

      # Second evaluation should use the cache
      {true, _updated_item} = Predicate.evaluate(predicate, item)
      # Counter should not have increased
      assert :counters.get(counter, 1) == 1

      # Third evaluation should also use the cache
      {true, _updated_item} = Predicate.evaluate(predicate, item)
      # Counter should still not have increased
      assert :counters.get(counter, 1) == 1

      # Cache stats should show 2 hits
      stats = Predicate.cache_stats()
      assert stats.hits == 2
      assert stats.misses == 1
    end

    test "different items do not share cache entries", %{
      predicate: predicate,
      item: item,
      counter: counter
    } do
      # First evaluation with original item
      {true, _updated_item} = Predicate.evaluate(predicate, item)
      assert :counters.get(counter, 1) == 1

      # Evaluation with different item should run predicate again
      item2 = Item.new(["status"], ["inactive"])
      {false, _updated_item} = Predicate.evaluate(predicate, item2)
      assert :counters.get(counter, 1) == 2

      # Evaluation with original item should use cache
      {true, _updated_item} = Predicate.evaluate(predicate, item)
      # Should not increase
      assert :counters.get(counter, 1) == 2

      # Evaluation with second item should use cache
      {false, _updated_item} = Predicate.evaluate(predicate, item2)
      # Should not increase
      assert :counters.get(counter, 1) == 2
    end

    test "disabling cache runs predicate each time", %{
      predicate: predicate,
      item: item,
      counter: counter
    } do
      # First evaluation
      {true, _updated_item} = Predicate.evaluate(predicate, item)
      assert :counters.get(counter, 1) == 1

      # Disable caching
      {:ok, _} = Predicate.with_caching(false)

      # Should run predicate each time when cache is disabled
      {true, _updated_item} = Predicate.evaluate(predicate, item)
      assert :counters.get(counter, 1) == 2

      {true, _updated_item} = Predicate.evaluate(predicate, item)
      assert :counters.get(counter, 1) == 3

      # Re-enable caching
      {:ok, _} = Predicate.with_caching(true)

      # First call with cache re-enabled should run predicate
      {true, _updated_item} = Predicate.evaluate(predicate, item)
      assert :counters.get(counter, 1) == 3

      # Subsequent calls should use cache
      {true, _updated_item} = Predicate.evaluate(predicate, item)
      # Should not increase
      assert :counters.get(counter, 1) == 3
    end

    test "clearing cache forces re-evaluation", %{
      predicate: predicate,
      item: item,
      counter: counter
    } do
      # First evaluation
      {true, _updated_item} = Predicate.evaluate(predicate, item)
      assert :counters.get(counter, 1) == 1

      # Second evaluation should use cache
      {true, _updated_item} = Predicate.evaluate(predicate, item)
      # No increase
      assert :counters.get(counter, 1) == 1

      # Clear cache
      :ok = Predicate.clear_cache()

      # Should run predicate again after cache cleared
      {true, _updated_item} = Predicate.evaluate(predicate, item)
      assert :counters.get(counter, 1) == 2
    end

    test "cache statistics reflect hits and misses", %{predicate: predicate, item: item} do
      # Clear all stats
      :ok = Predicate.clear_cache()

      # Get initial stats
      initial_stats = Predicate.cache_stats()
      assert initial_stats.hits == 0
      assert initial_stats.misses == 0

      # First evaluation (miss)
      {true, _updated_item} = Predicate.evaluate(predicate, item)

      miss_stats = Predicate.cache_stats()
      assert miss_stats.hits == 0
      assert miss_stats.misses == 1

      # Second evaluation (hit)
      {true, _updated_item} = Predicate.evaluate(predicate, item)

      hit_stats = Predicate.cache_stats()
      assert hit_stats.hits == 1
      assert hit_stats.misses == 1

      # Different item (miss)
      item2 = Item.new(["status"], ["inactive"])
      {false, _updated_item} = Predicate.evaluate(predicate, item2)

      more_stats = Predicate.cache_stats()
      assert more_stats.hits == 1
      assert more_stats.misses == 2
    end
  end
end
