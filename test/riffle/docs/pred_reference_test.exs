defmodule Riffle.Docs.PredReferenceTest do
  use ExUnit.Case, async: true

  alias Riffle.DocHelpers
  alias Riffle.Predicate.Item

  # docs/pred-language.md documents a language, and a language reference that
  # drifts is worse than none: a reader trusts it and writes something that
  # does not work. So the reference is checked by the code that really reads
  # `.pred` text, not by eye.
  #
  # Two claims, two fences. Every complete snippet in it loads -- parses,
  # extracts, and materialises with every reference resolved. Every expression
  # in it is a form the evaluator actually accepts. And the surface is covered
  # rather than sampled: the standard library enumerates itself, and every
  # builder it finds must appear in the document.

  @reference "docs/pred-language.md"

  # The fields, tags and metadata the documented expressions read.
  defp item do
    ["status", "tier", "age", "score", "email", "verified"]
    |> Item.new(["active", "premium", "42", "7.5", "user@example.com", "yes"])
    |> Item.add_tag(:seen)
    |> Item.add_metadata(%{source: :csv})
  end

  describe "the .pred snippets" do
    test "fence: every snippet in the reference loads and materialises" do
      snippets = DocHelpers.code_blocks(@reference, "pred")

      assert snippets != []

      failures =
        for {snippet, index} <- Enum.with_index(snippets, 1),
            result = DocHelpers.pred_load(snippet),
            result != :ok,
            do: {index, snippet, result}

      assert failures == []
    end

    test "control: a snippet that is not a definition is reported, not accepted" do
      assert {:error, {:invalid_dsl, message}} = DocHelpers.pred_load("banana(:x, \"no\") do end")

      assert message =~ "unrecognised top-level statement"
    end

    test "control: a snippet whose reference does not resolve is reported" do
      snippet = "loop(:orphan, \"Refers to nothing\") do\n  predicate(:missing)\nend"

      assert {:error, _reason} = DocHelpers.pred_load(snippet)
    end
  end

  describe "the expression language" do
    test "fence: every documented expression is a form the evaluator accepts" do
      expressions = DocHelpers.expressions(@reference)

      assert expressions != []

      failures =
        for expression <- expressions,
            result = DocHelpers.evaluation(expression, item()),
            result != :ok,
            do: {expression, result}

      assert failures == []
    end

    test "control: a form outside the language is reported, not quietly tolerated" do
      assert {:raised, message} = DocHelpers.evaluation("String.upcase(@status)", item())

      assert message =~ "Unsupported expression"
    end
  end

  describe "the standard library" do
    test "fence: every public builder appears in the reference" do
      builders = DocHelpers.standard_lib_predicates()

      assert length(builders) > 20

      text = File.read!(@reference)

      missing =
        for builder <- builders,
            reference = DocHelpers.standard_lib_reference(builder),
            not String.contains?(text, reference),
            do: reference

      assert missing == []
    end

    test "control: the surface is derived from the modules, not transcribed" do
      builders = DocHelpers.standard_lib_predicates()

      assert {Riffle.Predicate.StandardLib.Text, :equals, 2} in builders
      assert {Riffle.Predicate.StandardLib, :all, 1} in builders

      assert DocHelpers.standard_lib_reference({Riffle.Predicate.StandardLib.Text, :equals, 2}) ==
               "STD.Text.equals/2"

      assert DocHelpers.standard_lib_reference({Riffle.Predicate.StandardLib, :all, 1}) ==
               "STD.all/1"
    end
  end
end
