defmodule Riffle.Predicate.LoopTest do
  use ExUnit.Case, async: true
  doctest Riffle.Predicate.Loop

  alias Riffle.Predicate
  alias Riffle.Predicate.Item
  alias Riffle.Predicate.Loop

  describe "new/3" do
    test "creates a new loop definition" do
      predicates = [Predicate.new(:test, "Test", fn _ -> true end)]
      loop = Loop.new(:test_loop, "Test loop", predicates)
      assert loop.name == :test_loop
      assert loop.description == "Test loop"
      assert loop.predicates == predicates
    end
  end

  describe "process/2" do
    setup do
      active_predicate =
        Predicate.new(:active, "Active users", fn item -> item.fields["status"] == "active" end)

      premium_predicate =
        Predicate.new(:premium, "Premium users", fn item -> item.fields["tier"] == "premium" end)

      loop = Loop.new(:test_loop, "Test loop", [active_predicate, premium_predicate])

      active_item = Item.new(["status", "tier"], ["active", "basic"])
      premium_item = Item.new(["status", "tier"], ["inactive", "premium"])
      neither_item = Item.new(["status", "tier"], ["inactive", "basic"])

      {:ok,
       loop: loop,
       active_item: active_item,
       premium_item: premium_item,
       neither_item: neither_item}
    end

    test "returns {true, tagged_item} when item matches a predicate", %{
      loop: loop,
      active_item: item
    } do
      {matched, updated_item} = Loop.process(loop, item)
      assert matched
      assert :active in updated_item.tags
    end

    test "returns {false, item} when item doesn't match any predicates", %{
      loop: loop,
      neither_item: item
    } do
      {matched, updated_item} = Loop.process(loop, item)
      refute matched
      assert updated_item.tags == []
    end

    test "applies all predicates and collects all tags", %{loop: loop} do
      item = Item.new(["status", "tier"], ["active", "premium"])
      {matched, updated_item} = Loop.process(loop, item)
      assert matched
      assert Enum.sort(updated_item.tags) == [:active, :premium]
    end
  end

  describe "filter/2" do
    setup do
      active_predicate =
        Predicate.new(:active, "Active users", fn item -> item.fields["status"] == "active" end)

      loop = Loop.new(:test_loop, "Test loop", [active_predicate])

      items = [
        Item.new(["status"], ["active"]),
        Item.new(["status"], ["inactive"])
      ]

      {:ok, loop: loop, items: items}
    end

    test "filters items that match at least one predicate", %{loop: loop, items: items} do
      filtered = loop |> Loop.filter(items) |> Enum.to_list()
      assert length(filtered) == 1
      assert List.first(filtered).fields["status"] == "active"
      assert List.first(filtered).tags == [:active]
    end

    test "returns empty list when no items match", %{loop: loop} do
      items = [Item.new(["status"], ["inactive"])]
      filtered = loop |> Loop.filter(items) |> Enum.to_list()
      assert filtered == []
    end
  end

  describe "add_predicate/2" do
    test "adds a predicate to a loop" do
      loop = Loop.new(:test_loop, "Test loop", [])
      predicate = Predicate.new(:test, "Test", fn _ -> true end)
      updated_loop = Loop.add_predicate(loop, predicate)
      assert length(updated_loop.predicates) == 1
      assert hd(updated_loop.predicates).name == :test
    end
  end
end
