defmodule Riffle.Predicate.Dsl.ExprMacroBugSimplifiedTest do
  use ExUnit.Case, async: true

  alias Riffle.Predicate.Item

  # This module demonstrates the issue in isolation
  defmodule TestModuleWithExpr do
    # Import the expr macro
    import Riffle.Predicate.Dsl.Macro, only: [expr: 1]

    # This works fine when executed
    def test_expr_direct do
      expr(@status == "active")
    end

    # This creates the body that will be passed to Predicate.create
    def make_predicate_body do
      quote do
        expr(@status == "active")
      end
    end

    # This simulates what happens in defpredicate macro
    def simulate_predicate_macro do
      body = make_predicate_body()

      # Extract the expression from the expr macro call
      # This is what the pattern matching in defpredicate does
      {:expr, _, [expr]} = body

      # Create the body tuple that create/1 expects
      expr_body = {:expr, expr}

      # Then it passes the expr body to Predicate.create
      fn_impl = Riffle.Predicate.create(expr_body)
      # And creates a new predicate with it
      Riffle.Predicate.new(:test_expr, "Test expr", fn_impl)
    end
  end

  test "expr macro produces the correct structure when called directly" do
    result = TestModuleWithExpr.test_expr_direct()
    # The expr macro should return a tuple with :expr and the expression
    assert {:expr, expression} = result
    # The expression is an AST tuple structure - not a keyword list
    # It represents @status == "active"
    assert is_tuple(expression)
  end

  test "using Macro.escape affects expr processing in predicates" do
    # Create a test item
    item = Item.new(["status"], ["active"])

    # Try the simulated macro expansion which now uses proper pattern matching
    predicate = TestModuleWithExpr.simulate_predicate_macro()

    # Capture debug output to avoid polluting test output
    ExUnit.CaptureIO.capture_io(fn ->
      IO.puts("Predicate: #{inspect(predicate)}")
    end)

    # Now it should work with our updated implementation
    {matched, updated_item} = Riffle.Predicate.evaluate(predicate, item)
    assert matched == true
    assert updated_item.tags == [:test_expr]
  end
end
