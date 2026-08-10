defmodule Riffle.Predicate.Dsl.ExprSyntaxTest do
  use ExUnit.Case, async: true

  alias Riffle.Predicate
  alias Riffle.Predicate.Item

  describe "expr pattern with direct pattern matching" do
    # Test the key functionality - that expr syntax works directly in the predicate definition
    defmodule TestSimplePredicates do
      use Riffle.Predicate.Dsl.Macro

      # Define with expr syntax - this should work with our pattern matching fix
      defpredicate :active_expr, "Active users (expr syntax)" do
        expr(@status == "active")
      end

      defpredicate :premium_expr, "Premium users (expr syntax)" do
        expr(@tier == "premium")
      end

      # Define with regular function syntax for comparison
      defpredicate :active_function, "Active users (function syntax)" do
        fn item -> item.fields["status"] == "active" end
      end
    end

    test "expr syntax works correctly in defpredicate with direct pattern matching" do
      # Create test items
      active_item = Item.new(["status"], ["active"])
      inactive_item = Item.new(["status"], ["inactive"])

      # Get the predicate definition
      active_pred_def = TestSimplePredicates.get_predicate(:active_expr)
      assert active_pred_def.name == :active_expr
      assert active_pred_def.description == "Active users (expr syntax)"

      # Use this definition to create an actual predicate
      active_pred = TestSimplePredicates.active_expr()

      # Test that the predicate works correctly
      {matched, updated_item} = Predicate.evaluate(active_pred, active_item)
      assert matched == true
      assert updated_item.tags == [:active_expr]

      {matched, _} = Predicate.evaluate(active_pred, inactive_item)
      assert matched == false
    end

    test "expr syntax works with different field expressions" do
      # Create test items
      premium_item = Item.new(["tier"], ["premium"])
      basic_item = Item.new(["tier"], ["basic"])

      # Get the premium predicate
      premium_pred = TestSimplePredicates.premium_expr()

      # Test the premium predicate works correctly
      {matched, updated_item} = Predicate.evaluate(premium_pred, premium_item)
      assert matched == true
      assert updated_item.tags == [:premium_expr]

      {matched, _} = Predicate.evaluate(premium_pred, basic_item)
      assert matched == false
    end

    test "function syntax predicates still work normally" do
      # Create test items
      active_item = Item.new(["status"], ["active"])
      inactive_item = Item.new(["status"], ["inactive"])

      # Get the predicate
      predicate = TestSimplePredicates.active_function()

      # Test it works
      {matched, updated_item} = Predicate.evaluate(predicate, active_item)
      assert matched == true
      assert updated_item.tags == [:active_function]

      {matched, _} = Predicate.evaluate(predicate, inactive_item)
      assert matched == false
    end
  end
end
