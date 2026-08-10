defmodule Riffle.Predicate.LoopCacheIntegrationTest do
  # Exercises the global named Cache GenServer -- cannot run async.
  use ExUnit.Case, async: false

  alias Riffle.Predicate
  alias Riffle.Predicate.Item
  alias Riffle.Predicate.Loop

  setup do
    :ok = Riffle.CacheHelpers.reset_cache()

    # Spy predicates count their evaluations per counter slot
    counters = :counters.new(3, [:atomics])

    active =
      Riffle.CacheHelpers.spy_predicate(:active, counters, 1, &(&1.fields["status"] == "active"))

    premium =
      Riffle.CacheHelpers.spy_predicate(:premium, counters, 2, &(&1.fields["tier"] == "premium"))

    verified =
      Riffle.CacheHelpers.spy_predicate(
        :verified,
        counters,
        3,
        &(&1.fields["verified"] == "true")
      )

    # Create a loop with these predicates
    loop = Loop.new(:user_signals, "User signals loop", [active, premium, verified])

    # Create test items
    active_premium =
      Item.new(
        ["status", "tier", "verified"],
        ["active", "premium", "true"]
      )

    active_basic =
      Item.new(
        ["status", "tier", "verified"],
        ["active", "basic", "false"]
      )

    inactive =
      Item.new(
        ["status", "tier", "verified"],
        ["inactive", "basic", "false"]
      )

    # Return test setup
    %{
      loop: loop,
      active_premium: active_premium,
      active_basic: active_basic,
      inactive: inactive,
      counters: counters
    }
  end

  describe "loop integration with cache" do
    test "matching items benefit from cached predicate evaluations",
         %{loop: loop, active_premium: item, counters: counters} do
      # First time processing should evaluate all predicates
      {true, updated_item} = Loop.process(loop, item)

      # All predicates should have been evaluated once
      # active
      assert :counters.get(counters, 1) == 1
      # premium
      assert :counters.get(counters, 2) == 1
      # verified
      assert :counters.get(counters, 3) == 1

      # Item should have all tags
      assert Enum.sort(updated_item.tags) == [:active, :premium, :verified]

      # Processing the same item again should use cached results
      {true, _} = Loop.process(loop, item)

      # No additional evaluations should have occurred
      # still 1
      assert :counters.get(counters, 1) == 1
      # still 1
      assert :counters.get(counters, 2) == 1
      # still 1
      assert :counters.get(counters, 3) == 1

      # Cache stats should show hits
      stats = Predicate.cache_stats()
      # One hit for each predicate
      assert stats.hits == 3
    end

    test "different items evaluate predicates separately",
         %{
           loop: loop,
           active_premium: item1,
           active_basic: item2,
           inactive: item3,
           counters: counters
         } do
      # Process first item (active premium)
      {true, _} = Loop.process(loop, item1)

      # All predicates evaluated once
      # active
      assert :counters.get(counters, 1) == 1
      # premium
      assert :counters.get(counters, 2) == 1
      # verified
      assert :counters.get(counters, 3) == 1

      # Process second item (active basic)
      {true, updated_item2} = Loop.process(loop, item2)

      # Additional evaluations for this item
      # active (+1)
      assert :counters.get(counters, 1) == 2
      # premium (+1)
      assert :counters.get(counters, 2) == 2
      # verified (+1)
      assert :counters.get(counters, 3) == 2

      # Item should have only the active tag
      assert Enum.sort(updated_item2.tags) == [:active]

      # Process third item (inactive)
      {false, _} = Loop.process(loop, item3)

      # Loop.process evaluates every predicate unconditionally (no
      # short-circuit), so a non-matching item still evaluates all three
      assert :counters.get(counters, 1) == 3
      assert :counters.get(counters, 2) == 3
      assert :counters.get(counters, 3) == 3

      # Processing first item again should use cache
      {true, _} = Loop.process(loop, item1)

      # Cache is keyed per {predicate, item}: the counters sit exactly
      # where item3's full evaluation left them
      assert :counters.get(counters, 1) == 3
      assert :counters.get(counters, 2) == 3
      assert :counters.get(counters, 3) == 3
    end

    test "clearing cache causes re-evaluation",
         %{loop: loop, active_premium: item, counters: counters} do
      # First time processing
      {true, _} = Loop.process(loop, item)

      # All predicates evaluated once
      assert :counters.get(counters, 1) == 1
      assert :counters.get(counters, 2) == 1
      assert :counters.get(counters, 3) == 1

      # Second time uses cache
      {true, _} = Loop.process(loop, item)
      # unchanged
      assert :counters.get(counters, 1) == 1

      # Clear cache
      :ok = Predicate.clear_cache()

      # Processing again should re-evaluate
      {true, _} = Loop.process(loop, item)

      # Predicates evaluated again
      assert :counters.get(counters, 1) == 2
      assert :counters.get(counters, 2) == 2
      assert :counters.get(counters, 3) == 2
    end

    test "invariant: the stream filter path shares the cached evaluation entry point",
         %{loop: loop, active_premium: item1, active_basic: item2, counters: counters} do
      # Prime the cache through the single-item path
      {true, _} = Loop.process(loop, item1)
      assert :counters.get(counters, 1) == 1

      # Streaming the same item through filter must hit the cache, not re-evaluate
      [_tagged] = loop |> Loop.filter([item1]) |> Enum.to_list()

      assert :counters.get(counters, 1) == 1
      assert :counters.get(counters, 2) == 1
      assert :counters.get(counters, 3) == 1

      # A fresh item through filter evaluates once and seeds the cache
      [_tagged2] = loop |> Loop.filter([item2]) |> Enum.to_list()

      assert :counters.get(counters, 1) == 2
      assert :counters.get(counters, 2) == 2
      assert :counters.get(counters, 3) == 2

      # The single-item path then reads what the stream path cached
      {true, _} = Loop.process(loop, item2)
      assert :counters.get(counters, 1) == 2
    end

    test "disabling cache prevents caching",
         %{loop: loop, active_premium: item, counters: counters} do
      # Disable caching
      {:ok, _} = Predicate.with_caching(false)

      # First time processing
      {true, _} = Loop.process(loop, item)

      # All predicates evaluated once
      assert :counters.get(counters, 1) == 1
      assert :counters.get(counters, 2) == 1
      assert :counters.get(counters, 3) == 1

      # Second time should evaluate again (no caching)
      {true, _} = Loop.process(loop, item)

      # Predicates evaluated again
      assert :counters.get(counters, 1) == 2
      assert :counters.get(counters, 2) == 2
      assert :counters.get(counters, 3) == 2

      # Cache stats should show no hits (since caching was disabled)
      stats = Predicate.cache_stats()
      assert stats.hits == 0
    end
  end
end
