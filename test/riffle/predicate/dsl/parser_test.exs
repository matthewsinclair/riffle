defmodule Riffle.Predicate.Dsl.ParserTest do
  use ExUnit.Case, async: true

  alias Riffle.Predicate.Dsl.Parser

  describe "parse/1" do
    test "successfully parses valid predicate syntax" do
      dsl = """
      predicate(:active, "Active users") do
        fn item -> item.fields["status"] == "active" end
      end
      """

      assert {:ok, _ast} = Parser.parse(dsl)
    end

    test "returns error for invalid syntax" do
      dsl = "invalid { syntax"
      assert {:error, error} = Parser.parse(dsl)
      assert %TokenMissingError{} = error
    end
  end

  describe "extract_predicates/1" do
    test "extracts predicate with name, description, and body" do
      dsl = """
      predicate(:active, "Active users") do
        fn item -> item.fields["status"] == "active" end
      end
      """

      {:ok, ast} = Parser.parse(dsl)
      [predicate] = Parser.extract_predicates(ast)

      assert predicate.name == :active
      assert predicate.description == "Active users"
      assert match?({:fn, _, _}, predicate.body)
    end

    test "extracts predicate without description" do
      dsl = """
      predicate(:active) do
        fn item -> item.fields["status"] == "active" end
      end
      """

      {:ok, ast} = Parser.parse(dsl)
      [predicate] = Parser.extract_predicates(ast)

      assert predicate.name == :active
      assert predicate.description == ""
      assert match?({:fn, _, _}, predicate.body)
    end

    test "extracts multiple predicates from block" do
      dsl = """
      predicate(:active, "Active users") do
        fn item -> item.fields["status"] == "active" end
      end

      predicate(:premium, "Premium users") do
        fn item -> item.fields["tier"] == "premium" end
      end
      """

      {:ok, ast} = Parser.parse(dsl)
      predicates = Parser.extract_predicates(ast)

      assert length(predicates) == 2
      assert Enum.map(predicates, & &1.name) == [:active, :premium]
    end

    test "returns empty list for non-predicate AST" do
      dsl = """
      other_thing(:name) do
        something
      end
      """

      {:ok, ast} = Parser.parse(dsl)
      predicates = Parser.extract_predicates(ast)

      assert predicates == []
    end
  end

  describe "extract_loops/1" do
    test "extracts loop with name, description, and predicate references" do
      dsl = """
      loop(:user_signals, "User signal detection") do
        predicate(:active)
        predicate(:premium)
      end
      """

      {:ok, ast} = Parser.parse(dsl)
      [loop] = Parser.extract_loops(ast)

      assert loop.name == :user_signals
      assert loop.description == "User signal detection"
      assert length(loop.predicates) == 2

      [pred1, pred2] = loop.predicates
      assert pred1.name == :active
      assert pred1.inline == false
      assert pred2.name == :premium
      assert pred2.inline == false
    end

    test "extracts loop with inline predicate definitions" do
      dsl = """
      loop(:user_signals, "User signal detection") do
        predicate(:active, "Active users") do
          fn item -> item.fields["status"] == "active" end
        end
        
        predicate(:premium) do
          fn item -> item.fields["tier"] == "premium" end
        end
      end
      """

      {:ok, ast} = Parser.parse(dsl)
      [loop] = Parser.extract_loops(ast)

      assert loop.name == :user_signals
      assert loop.description == "User signal detection"
      assert length(loop.predicates) == 2

      [pred1, pred2] = loop.predicates
      assert pred1.name == :active
      assert pred1.description == "Active users"
      assert pred1.inline == true
      assert match?({:fn, _, _}, pred1.body)

      assert pred2.name == :premium
      assert pred2.description == ""
      assert pred2.inline == true
      assert match?({:fn, _, _}, pred2.body)
    end

    test "extracts multiple loops from block" do
      dsl = """
      loop(:signals, "Signal detection") do
        predicate(:active)
      end

      loop(:inferences, "Inference processing") do
        predicate(:premium)
      end
      """

      {:ok, ast} = Parser.parse(dsl)
      loops = Parser.extract_loops(ast)

      assert length(loops) == 2
      assert Enum.map(loops, & &1.name) == [:signals, :inferences]
    end
  end
end
