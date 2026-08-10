defmodule Riffle.PredicateTest do
  # Toggles the global cache configuration -- cannot run async.
  use ExUnit.Case, async: false
  doctest Riffle.Predicate

  alias Riffle.Predicate
  alias Riffle.Predicate.Item

  setup do
    # Disable caching so evaluation is deterministic; restore the prior
    # configuration afterwards rather than assuming it was enabled.
    %{enabled: prior_enabled} = Riffle.Predicate.Cache.config()
    {:ok, _} = Predicate.with_caching(false)

    on_exit(fn -> {:ok, _} = Predicate.with_caching(prior_enabled) end)

    :ok
  end

  describe "new/3" do
    test "creates a new predicate definition" do
      function = fn _ -> true end
      predicate = Predicate.new(:test, "Test predicate", function)
      assert predicate.name == :test
      assert predicate.description == "Test predicate"
      assert predicate.function == function
    end
  end

  describe "evaluate/2" do
    setup do
      item = Item.new(["status"], ["active"])
      {:ok, item: item}
    end

    test "returns {false, item} when predicate returns false", %{item: item} do
      predicate = Predicate.new(:test, "Test", fn _ -> false end)
      {matched, updated_item} = Predicate.evaluate(predicate, item)
      refute matched
      assert updated_item == item
    end

    test "returns {true, tagged_item} when predicate returns true", %{item: item} do
      predicate = Predicate.new(:test, "Test", fn _ -> true end)
      {matched, updated_item} = Predicate.evaluate(predicate, item)
      assert matched
      assert updated_item.tags == [:test]
    end

    test "returns {true, multi_tagged_item} when predicate returns tag list", %{item: item} do
      predicate = Predicate.new(:test, "Test", fn _ -> [:tag1, :tag2] end)
      {matched, updated_item} = Predicate.evaluate(predicate, item)
      assert matched
      assert Enum.sort(updated_item.tags) == [:tag1, :tag2]
    end

    test "returns {true, tagged_item_with_metadata} when predicate returns {true, metadata}", %{
      item: item
    } do
      predicate = Predicate.new(:test, "Test", fn _ -> {true, %{count: 42}} end)
      {matched, updated_item} = Predicate.evaluate(predicate, item)
      assert matched
      assert updated_item.tags == [:test]
      assert updated_item.metadata == %{count: 42}
    end

    test "returns {true, multi_tagged_item_with_metadata} when predicate returns {tags, metadata}",
         %{item: item} do
      predicate = Predicate.new(:test, "Test", fn _ -> {[:tag1, :tag2], %{count: 42}} end)
      {matched, updated_item} = Predicate.evaluate(predicate, item)
      assert matched
      assert Enum.sort(updated_item.tags) == [:tag1, :tag2]
      assert updated_item.metadata == %{count: 42}
    end

    test "raises error on invalid predicate result", %{item: item} do
      predicate = Predicate.new(:test, "Test", fn _ -> "invalid" end)

      assert_raise ArgumentError, fn ->
        Predicate.evaluate(predicate, item)
      end
    end
  end

  describe "from_function/3" do
    test "creates a predicate from an anonymous function" do
      function = fn item -> item.fields["status"] == "active" end
      predicate = Predicate.from_function(:active, "Active users", function)
      assert predicate.name == :active
      assert predicate.description == "Active users"
      assert is_function(predicate.function, 1)

      item = Item.new(["status"], ["active"])
      {matched, _} = Predicate.evaluate(predicate, item)
      assert matched
    end
  end

  describe "from_call/3" do
    defmodule TestHelperModule do
      def is_active(item), do: item.fields["status"] == "active"
    end

    test "creates a predicate from a function reference" do
      predicate = Predicate.from_call(:active, "Active users", &TestHelperModule.is_active/1)
      assert predicate.name == :active
      assert predicate.description == "Active users"
      assert is_function(predicate.function, 1)

      item = Item.new(["status"], ["active"])
      {matched, _} = Predicate.evaluate(predicate, item)
      assert matched
    end
  end

  describe "from_check/3" do
    test "creates a predicate that checks for tag presence" do
      predicate = Predicate.from_check(:has_tags, "Has specific tags", [:tag1, :tag2])

      item_with_no_tags = Item.new([], [])
      {matched, _} = Predicate.evaluate(predicate, item_with_no_tags)
      refute matched

      item_with_one_tag = Item.add_tag(item_with_no_tags, :tag1)
      {matched, _} = Predicate.evaluate(predicate, item_with_one_tag)
      refute matched

      item_with_both_tags = Item.add_tags(item_with_no_tags, [:tag1, :tag2])
      {matched, _} = Predicate.evaluate(predicate, item_with_both_tags)
      assert matched
    end
  end

  describe "from_expression/3" do
    test "creates a predicate from an expression" do
      result = Predicate.from_expression(:test, "Test", ~s(fields["status"] == "active"))
      assert match?({:ok, %{name: :test, description: "Test"}}, result)

      {:ok, predicate} = result
      item1 = Item.new(["status"], ["active"])
      item2 = Item.new(["status"], ["inactive"])

      {matched1, _} = Predicate.evaluate(predicate, item1)
      {matched2, _} = Predicate.evaluate(predicate, item2)

      assert matched1 == true
      assert matched2 == false
    end
  end
end
