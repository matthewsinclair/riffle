defmodule Riffle.Predicate.Dsl.ExprTest do
  use ExUnit.Case, async: true

  alias Riffle.Predicate
  alias Riffle.Predicate.Item
  alias Riffle.Predicate.Loop
  alias Riffle.Predicate.Pipeline

  # The one DSL fixture shared by every describe below: expr bodies in AST
  # form and string form, mixed with function syntax, composed into a loop
  # and a pipeline exactly as a consumer would write them.
  defmodule ExprPredicates do
    use Riffle.Predicate.Dsl.Macro

    defpredicate :active_expr, "Active users (expr syntax)" do
      expr(@status == "active")
    end

    defpredicate :premium_string_expr, "Premium users (string expr body)" do
      {:expr, "@tier == \"premium\""}
    end

    defpredicate :active_function, "Active users (function syntax)" do
      fn item -> item.fields["status"] == "active" end
    end

    defloop :mixed_signals, "Function + expr predicates in one loop" do
      predicate(:active_function)
      predicate(:premium_string_expr)
    end

    defpipeline :expr_pipeline, "Pipeline whose filtering is expr-driven" do
      loop(:mixed_signals)
    end
  end

  describe "the expr macro" do
    test "success: called directly it yields the {:expr, ast} body form" do
      import Riffle.Predicate.Dsl.Macro, only: [expr: 1]

      assert {:expr, expression} = expr(@status == "active")
      assert is_tuple(expression)
    end
  end

  describe "expr bodies in defpredicate" do
    test "success: AST expr syntax evaluates and tags" do
      predicate = ExprPredicates.active_expr()

      assert {true, %Item{tags: [:active_expr]}} =
               Predicate.evaluate(predicate, Item.new(["status"], ["active"]))

      assert {false, %Item{tags: []}} =
               Predicate.evaluate(predicate, Item.new(["status"], ["inactive"]))
    end

    test "success: string expr bodies evaluate and tag" do
      predicate = ExprPredicates.premium_string_expr()

      assert {true, %Item{tags: [:premium_string_expr]}} =
               Predicate.evaluate(predicate, Item.new(["tier"], ["premium"]))

      assert {false, %Item{tags: []}} =
               Predicate.evaluate(predicate, Item.new(["tier"], ["basic"]))
    end
  end

  describe "expr predicates composed through the DSL" do
    test "success: a macro-generated loop mixing function and expr predicates filters and tags" do
      loop = ExprPredicates.mixed_signals()

      assert %Loop{name: :mixed_signals} = loop

      items = [
        Item.new(["status", "tier"], ["active", "premium"]),
        Item.new(["status", "tier"], ["inactive", "premium"]),
        Item.new(["status", "tier"], ["inactive", "basic"])
      ]

      assert [
               %Item{fields: %{"status" => "active"}, tags: tags_one},
               %Item{
                 fields: %{"status" => "inactive", "tier" => "premium"},
                 tags: [:premium_string_expr]
               }
             ] = loop |> Loop.filter(items) |> Enum.to_list()

      assert Enum.sort(tags_one) == [:active_function, :premium_string_expr]
    end

    test "success: a macro-generated pipeline runs expr-driven filtering end to end" do
      pipeline = ExprPredicates.expr_pipeline()

      assert %Pipeline{name: :expr_pipeline} = pipeline

      items = [
        Item.new(["status", "tier"], ["active", "basic"]),
        Item.new(["status", "tier"], ["inactive", "basic"])
      ]

      assert [%Item{fields: %{"status" => "active"}, tags: [:active_function]}] =
               pipeline |> Pipeline.process(items) |> Enum.to_list()
    end
  end

  describe "expr evaluation drives real pipeline filtering" do
    test "invariant: survivors carry exactly the tags of the expr predicates they matched" do
      active_premium = Item.new(["status", "tier"], ["active", "premium"])
      active_basic = Item.new(["status", "tier"], ["active", "basic"])
      inactive_premium = Item.new(["status", "tier"], ["inactive", "premium"])
      inactive_basic = Item.new(["status", "tier"], ["inactive", "basic"])

      items = [active_premium, active_basic, inactive_premium, inactive_basic]

      active_predicate =
        Predicate.new(
          :active_expr,
          "Active users (expr)",
          Predicate.create({:expr, "@status == \"active\""})
        )

      premium_predicate =
        Predicate.new(
          :premium_expr,
          "Premium users (expr)",
          Predicate.create({:expr, "@tier == \"premium\""})
        )

      test_loop = Loop.new(:test_loop, "Test loop", [active_predicate, premium_predicate])
      pipeline = Pipeline.new(:test_pipeline, "Test pipeline", [test_loop])

      # Any-match within the loop: only inactive_basic dies, and each
      # survivor carries exactly the tags of the expr predicates it matched
      results =
        pipeline
        |> Pipeline.process(items)
        |> Enum.to_list()

      assert [
               %Item{
                 fields: %{"status" => "active", "tier" => "premium"},
                 tags: [:premium_expr, :active_expr]
               },
               %Item{fields: %{"tier" => "basic"}, tags: [:active_expr]},
               %Item{
                 fields: %{"status" => "inactive", "tier" => "premium"},
                 tags: [:premium_expr]
               }
             ] = results
    end
  end
end
