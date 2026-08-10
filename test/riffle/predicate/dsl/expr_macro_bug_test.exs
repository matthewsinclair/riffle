defmodule Riffle.Predicate.Dsl.ExprMacroBugTest do
  use ExUnit.Case, async: true

  alias Riffle.Predicate.Item

  # Test with string expressions (workaround for the issue)
  describe "expr in DSL macro with string expressions (workaround)" do
    defmodule TestPredicatesWithStringExpr do
      use Riffle.Predicate.Dsl.Macro

      # Define with function syntax (works correctly)
      defpredicate :active_function, "Active users (function syntax)" do
        fn item -> item.fields["status"] == "active" end
      end

      # Define with expr syntax using a string expression (workaround)
      defpredicate :active_expr_string, "Active users (expr string syntax)" do
        {:expr, "@status == \"active\""}
      end

      # Define a loop containing both predicate types
      defloop :mixed_signals, "Mixed syntax signals" do
        predicate(:active_function)
        predicate(:active_expr_string)
      end

      # Define a pipeline containing the loop
      defpipeline :test_pipeline, "Test pipeline" do
        loop(:mixed_signals)
      end
    end

    test "string-based expr syntax works as a workaround" do
      # Create test items
      active_item = Item.new(["status"], ["active"])
      inactive_item = Item.new(["status"], ["inactive"])

      # Get the predicate
      predicate = TestPredicatesWithStringExpr.active_expr_string()

      # Test it works
      {matched, _} = Riffle.Predicate.evaluate(predicate, active_item)
      assert matched == true

      {matched, _} = Riffle.Predicate.evaluate(predicate, inactive_item)
      assert matched == false
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

        :active_expr_string ->
          # String-based expr predicate
          expr_func = Riffle.Predicate.create({:expr, "@status == \"active\""})

          Riffle.Predicate.new(
            :active_expr_string,
            "Active users (expr string syntax)",
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
            get_predicate(:active_expr_string)
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

    test "mixed predicates in loop and pipeline with string expr" do
      # Create test items
      active_item = Item.new(["status"], ["active"])

      # Get the resolved pipeline with all references properly populated
      pipeline = get_resolved_pipeline(:test_pipeline)

      # Test it works - must convert Stream to list before using length
      filtered_items = Riffle.Predicate.Pipeline.process(pipeline, [active_item])
      results = Enum.to_list(filtered_items)
      assert length(results) == 1
    end
  end

  # This is a direct test of the predicate creation to diagnose the issue
  test "direct predicate creation with expr" do
    # Use the expr macro directly
    import Riffle.Predicate.Dsl.Macro, only: [expr: 1]

    # This works because the expr macro is invoked directly
    direct_expr = expr(@status == "active")
    assert is_tuple(direct_expr)
    assert elem(direct_expr, 0) == :expr

    # Create a predicate with the direct expr
    direct_predicate =
      Riffle.Predicate.new(
        :direct_expr,
        "Direct expr test",
        Riffle.Predicate.create(direct_expr)
      )

    # Test it works on an actual item
    active_item = Item.new(["status"], ["active"])
    {matched, _} = Riffle.Predicate.evaluate(direct_predicate, active_item)
    assert matched == true
  end
end
