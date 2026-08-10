defmodule Riffle.Predicate.Dsl.ExprMacroCorrectTest do
  use ExUnit.Case, async: true

  alias Riffle.Predicate.Item

  describe "expr in DSL macro with proper implementation" do
    defmodule TestPredicates do
      use Riffle.Predicate.Dsl.Macro

      # Define with function syntax (works correctly)
      defpredicate :active_function, "Active users (function syntax)" do
        fn item -> item.fields["status"] == "active" end
      end

      # Define with expr syntax (should work with our fix)
      defpredicate :active_expr, "Active users (expr syntax)" do
        expr(@status == "active")
      end

      defpredicate :premium_expr, "Premium users (expr syntax)" do
        expr(@tier == "premium")
      end

      # Define a loop containing both predicate types
      defloop :mixed_signals, "Mixed syntax signals" do
        predicate(:active_function)
        predicate(:active_expr)
      end

      # Define a pipeline containing the loop
      defpipeline :test_pipeline, "Test pipeline" do
        loop(:mixed_signals)
      end
    end

    test "function syntax works in defpredicate" do
      # Create test items
      active_item = Item.new(["status"], ["active"])
      inactive_item = Item.new(["status"], ["inactive"])

      # Get the predicate
      predicate = TestPredicates.active_function()

      # Test it works
      {matched, _} = Riffle.Predicate.evaluate(predicate, active_item)
      assert matched == true

      {matched, _} = Riffle.Predicate.evaluate(predicate, inactive_item)
      assert matched == false
    end

    test "expr syntax works in defpredicate with fix" do
      # Create test items
      active_item = Item.new(["status"], ["active"])
      inactive_item = Item.new(["status"], ["inactive"])

      # Get the predicate
      predicate = TestPredicates.active_expr()

      # Test it works now with our fix
      {matched, _} = Riffle.Predicate.evaluate(predicate, active_item)
      assert matched == true

      {matched, _} = Riffle.Predicate.evaluate(predicate, inactive_item)
      assert matched == false
    end

    test "mixed predicates in loop" do
      # Create test items
      active_item = Item.new(["status"], ["active"])
      inactive_item = Item.new(["status"], ["inactive"])

      # Get the loop
      loop = TestPredicates.mixed_signals()

      # Process items through the loop
      filtered_items = Riffle.Predicate.Loop.filter(loop, [active_item, inactive_item])
      results = Enum.to_list(filtered_items)

      # Only active items should match
      assert length(results) == 1
      assert hd(results).fields["status"] == "active"
    end

    # Helper to create properly resolved predicates for test
    defp get_predicate(name) do
      case name do
        :active_function ->
          # Direct function predicate - note order of arguments is important!
          Riffle.Predicate.new(
            :active_function,
            "Active users (function syntax)",
            fn item -> item.fields["status"] == "active" end
          )

        :active_expr ->
          # Create expr predicate directly
          expr_func = Riffle.Predicate.create({:expr, "@status == \"active\""})

          Riffle.Predicate.new(
            :active_expr,
            "Active users (expr syntax)",
            expr_func
          )
      end
    end

    # Helper to create a resolved loop
    defp get_resolved_loop(name) do
      case name do
        :mixed_signals ->
          # Create loop with resolved predicates
          predicates = [
            get_predicate(:active_function),
            get_predicate(:active_expr)
          ]

          Riffle.Predicate.Loop.new(:mixed_signals, "Mixed syntax signals", predicates)
      end
    end

    # Helper to create a resolved pipeline
    defp get_resolved_pipeline(name) do
      case name do
        :test_pipeline ->
          # Create pipeline with resolved loops
          loops = [get_resolved_loop(:mixed_signals)]
          Riffle.Predicate.Pipeline.new(:test_pipeline, "Test pipeline", loops)
      end
    end

    test "pipeline processes items correctly" do
      # Create test items
      active_item = Item.new(["status"], ["active"])
      inactive_item = Item.new(["status"], ["inactive"])

      # Get the resolved pipeline with all references properly populated
      pipeline = get_resolved_pipeline(:test_pipeline)

      # Process items through the pipeline
      filtered_items =
        Riffle.Predicate.Pipeline.process(pipeline, [active_item, inactive_item])

      results = Enum.to_list(filtered_items)

      # Only active items should match
      assert length(results) == 1
      assert hd(results).fields["status"] == "active"
    end
  end
end
