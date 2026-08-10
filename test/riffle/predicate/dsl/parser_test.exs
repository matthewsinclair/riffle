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
      assert Exception.message(error) =~ "missing terminator"
    end
  end

  describe "extract_definitions!/1 predicates" do
    test "extracts predicate with name, description, and body" do
      dsl = """
      predicate(:active, "Active users") do
        fn item -> item.fields["status"] == "active" end
      end
      """

      assert %{predicates: [predicate]} = extract!(dsl)

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

      assert %{predicates: [predicate]} = extract!(dsl)

      assert predicate.name == :active
      assert predicate.description == ""
      assert match?({:fn, _, _}, predicate.body)
    end

    test "extracts multiple predicates in source order" do
      dsl = """
      predicate(:active, "Active users") do
        fn item -> item.fields["status"] == "active" end
      end

      predicate(:premium, "Premium users") do
        fn item -> item.fields["tier"] == "premium" end
      end
      """

      assert %{predicates: predicates} = extract!(dsl)

      assert Enum.map(predicates, & &1.name) == [:active, :premium]
    end
  end

  describe "extract_definitions!/1 loops" do
    test "extracts loop with name, description, and predicate references" do
      dsl = """
      loop(:user_signals, "User signal detection") do
        predicate(:active)
        predicate(:premium)
      end
      """

      assert %{loops: [loop]} = extract!(dsl)

      assert loop.name == :user_signals
      assert loop.description == "User signal detection"

      assert loop.predicates == [
               %{name: :active, inline: false},
               %{name: :premium, inline: false}
             ]
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

      assert %{loops: [loop]} = extract!(dsl)

      assert loop.name == :user_signals
      assert loop.description == "User signal detection"

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

    test "extracts multiple loops in source order" do
      dsl = """
      loop(:signals, "Signal detection") do
        predicate(:active)
      end

      loop(:inferences, "Inference processing") do
        predicate(:premium)
      end
      """

      assert %{loops: loops} = extract!(dsl)

      assert Enum.map(loops, & &1.name) == [:signals, :inferences]
    end
  end

  describe "extract_definitions!/1 pipelines" do
    test "extracts pipeline with loop references and buckets mixed sources" do
      dsl = """
      predicate(:active, "Active users") do
        fn item -> item.fields["status"] == "active" end
      end

      loop(:user_signals, "User signal detection") do
        predicate(:active)
      end

      pipeline(:user_pipeline, "User processing pipeline") do
        loop(:user_signals)
      end
      """

      definitions = extract!(dsl)

      assert [%{name: :active}] = definitions.predicates
      assert [%{name: :user_signals}] = definitions.loops

      assert [
               %{
                 name: :user_pipeline,
                 description: "User processing pipeline",
                 loops: [%{name: :user_signals, inline: false}]
               }
             ] = definitions.pipelines
    end
  end

  describe "extract_definitions!/1 completeness" do
    test "failure: an unrecognised top-level statement raises, never silently drops" do
      dsl = """
      other_thing(:name) do
        something
      end
      """

      assert_raise ArgumentError, ~r/unrecognised top-level statement/, fn ->
        extract!(dsl)
      end
    end
  end

  defp extract!(dsl) do
    assert {:ok, ast} = Parser.parse(dsl)
    Parser.extract_definitions!(ast)
  end
end
