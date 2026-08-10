defmodule Riffle.Predicate.ItemTest do
  use ExUnit.Case, async: true
  doctest Riffle.Predicate.Item

  alias Riffle.Predicate.Item

  describe "new/2" do
    test "creates a new item with fields" do
      item = Item.new(["id", "name"], ["1", "John"])
      assert item.fieldnames == ["id", "name"]
      assert item.fields == %{"id" => "1", "name" => "John"}
      assert item.tags == []
      assert item.metadata == %{}
    end

    test "raises when fieldnames and values have different lengths" do
      assert_raise FunctionClauseError, fn ->
        Item.new(["id", "name"], ["1"])
      end
    end
  end

  describe "add_tag/2" do
    test "adds a tag to an item" do
      item = Item.new([], [])
      updated = Item.add_tag(item, :test_tag)
      assert updated.tags == [:test_tag]
    end

    test "doesn't add duplicate tags" do
      item = %Item{tags: [:existing]}
      updated = Item.add_tag(item, :existing)
      assert updated.tags == [:existing]
    end
  end

  describe "add_tags/2" do
    test "adds multiple tags to an item" do
      item = Item.new([], [])
      updated = Item.add_tags(item, [:tag1, :tag2])
      assert Enum.sort(updated.tags) == [:tag1, :tag2]
    end

    test "doesn't add duplicate tags" do
      item = %Item{tags: [:tag1]}
      updated = Item.add_tags(item, [:tag1, :tag2])
      assert Enum.sort(updated.tags) == [:tag1, :tag2]
    end
  end

  describe "add_metadata/2" do
    test "adds metadata to an item" do
      item = Item.new([], [])
      updated = Item.add_metadata(item, %{count: 42})
      assert updated.metadata == %{count: 42}
    end

    test "merges with existing metadata" do
      item = %Item{metadata: %{existing: "value"}}
      updated = Item.add_metadata(item, %{new: "data"})
      assert updated.metadata == %{existing: "value", new: "data"}
    end

    test "overwrites existing keys" do
      item = %Item{metadata: %{key: "old"}}
      updated = Item.add_metadata(item, %{key: "new"})
      assert updated.metadata == %{key: "new"}
    end
  end

  describe "has_tag?/2" do
    test "returns true when item has the tag" do
      item = %Item{tags: [:tag1, :tag2]}
      assert Item.has_tag?(item, :tag1)
    end

    test "returns false when item doesn't have the tag" do
      item = %Item{tags: [:tag1]}
      refute Item.has_tag?(item, :nonexistent)
    end
  end

  describe "get_field/2" do
    test "returns the field value" do
      item = Item.new(["name"], ["John"])
      assert Item.get_field(item, "name") == "John"
    end

    test "returns nil for nonexistent fields" do
      item = Item.new([], [])
      assert Item.get_field(item, "nonexistent") == nil
    end
  end

  describe "get_metadata/2" do
    test "returns the metadata value" do
      item = %Item{metadata: %{count: 42}}
      assert Item.get_metadata(item, :count) == 42
    end

    test "returns nil for nonexistent keys" do
      item = Item.new([], [])
      assert Item.get_metadata(item, :nonexistent) == nil
    end
  end
end
