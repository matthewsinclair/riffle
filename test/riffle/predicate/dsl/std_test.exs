defmodule Riffle.Predicate.Dsl.STDTest do
  use ExUnit.Case, async: true

  alias Riffle.Predicate.Dsl.STD
  alias Riffle.Predicate.Dsl.Loader
  alias Riffle.Predicate.Item

  describe "STD interface" do
    test "STD module functions are directly accessible" do
      # Test a few functions as samples
      predicate_fn = STD.Boolean.is_true("verified")
      assert is_function(predicate_fn, 1)

      predicate_fn = STD.Text.equals("status", "active")
      assert is_function(predicate_fn, 1)

      predicate_fn = STD.Numeric.greater_than("age", 18)
      assert is_function(predicate_fn, 1)
    end

    test "STD functions match StandardLib behavior" do
      item = Item.new(["status", "verified", "age"], ["active", "true", "25"])

      # Test the forwarding for a few functions
      std_pred = STD.Boolean.is_true("verified")
      std_result = std_pred.(item)

      standardlib_pred = Riffle.Predicate.StandardLib.Boolean.is_true("verified")
      standardlib_result = standardlib_pred.(item)

      assert std_result == standardlib_result
      assert std_result == true
    end
  end

  describe "DSL integration" do
    test "can use STD shorthand in DSL strings" do
      dsl_content = """
      predicate(:active_user, "Active users") do
        call &STD.Boolean.is_true/1, ["active"]
      end
      """

      {:ok, %{predicates: [pred_def]}} = Loader.load_string(dsl_content)
      assert pred_def.name == :active_user
      assert pred_def.description == "Active users"
    end

    test "both STD and full StandardLib paths work in DSL" do
      dsl_content = """
      predicate(:active_with_short, "Active users (short syntax)") do
        call &STD.Boolean.is_true/1, ["active"]
      end

      predicate(:active_with_long, "Active users (long syntax)") do
        call &Riffle.Predicate.StandardLib.Boolean.is_true/1, ["active"]
      end
      """

      {:ok, %{predicates: pred_defs}} = Loader.load_string(dsl_content)
      assert length(pred_defs) == 2

      [short, long] = pred_defs
      assert short.name == :active_with_short
      assert long.name == :active_with_long
    end
  end

  describe "Module alias helper" do
    defmodule TestPredicates do
      use Riffle.Predicate.STD

      def active_check do
        STD.Boolean.is_true("active")
      end
    end

    test "using helper provides STD alias" do
      pred_fn = TestPredicates.active_check()
      assert is_function(pred_fn, 1)

      item = Item.new(["active"], ["true"])
      assert pred_fn.(item)
    end
  end
end
