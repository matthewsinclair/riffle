defmodule Riffle.Predicate.Dsl.EvaluatorTest do
  use ExUnit.Case, async: true
  alias Riffle.Predicate.Dsl.Evaluator
  alias Riffle.Predicate.Item

  test "parse/1 with simple equality expression" do
    expr = ~s(fields["status"] == "active")
    assert {:ok, func} = Evaluator.parse(expr)
    assert is_function(func, 1)

    item1 = Item.new(["status"], ["active"])
    item2 = Item.new(["status"], ["inactive"])

    assert func.(item1) == true
    assert func.(item2) == false
  end

  test "parse/1 with numeric comparison" do
    expr = ~s(fields["age"] > "30")
    assert {:ok, func} = Evaluator.parse(expr)

    item1 = Item.new(["age"], ["35"])
    item2 = Item.new(["age"], ["25"])

    assert func.(item1) == true
    assert func.(item2) == false
  end

  test "parse/1 with logical operators" do
    expr = ~s(fields["status"] == "active" && fields["tier"] == "premium")
    assert {:ok, func} = Evaluator.parse(expr)

    item1 = Item.new(["status", "tier"], ["active", "premium"])
    item2 = Item.new(["status", "tier"], ["active", "basic"])

    assert func.(item1) == true
    assert func.(item2) == false
  end

  test "create_function/1 with quoted expression" do
    expr = Code.string_to_quoted!(~s(fields["status"] == "active"))
    func = Evaluator.create_function(expr)

    item1 = Item.new(["status"], ["active"])
    item2 = Item.new(["status"], ["inactive"])

    assert func.(item1) == true
    assert func.(item2) == false
  end

  test "evaluate/2 with field access" do
    expr = Code.string_to_quoted!(~s(fields["status"]))
    item = Item.new(["status"], ["active"])

    assert Evaluator.evaluate(expr, item) == "active"
  end

  test "evaluate/2 with comparisons" do
    expr = Code.string_to_quoted!(~s(fields["status"] == "active"))
    item1 = Item.new(["status"], ["active"])
    item2 = Item.new(["status"], ["inactive"])

    assert Evaluator.evaluate(expr, item1) == true
    assert Evaluator.evaluate(expr, item2) == false
  end

  test "evaluate/2 with logical operators" do
    expr = Code.string_to_quoted!(~s(fields["status"] == "active" || fields["tier"] == "premium"))
    item1 = Item.new(["status", "tier"], ["inactive", "premium"])
    item2 = Item.new(["status", "tier"], ["active", "basic"])
    item3 = Item.new(["status", "tier"], ["inactive", "basic"])

    assert Evaluator.evaluate(expr, item1) == true
    assert Evaluator.evaluate(expr, item2) == true
    assert Evaluator.evaluate(expr, item3) == false
  end

  test "type conversion helpers" do
    item = Item.new(["number_string", "true_string", "text"], ["123", "true", "abc"])

    # to_integer
    expr = Code.string_to_quoted!(~s|to_integer(fields["number_string"])|)
    assert Evaluator.evaluate(expr, item) == 123

    # to_float
    expr = Code.string_to_quoted!(~s|to_float(fields["number_string"])|)
    assert Evaluator.evaluate(expr, item) == 123.0

    # to_string
    expr = Code.string_to_quoted!(~s|to_string(to_integer(fields["number_string"]))|)
    assert Evaluator.evaluate(expr, item) == "123"

    # to_boolean
    expr = Code.string_to_quoted!(~s|to_boolean(fields["true_string"])|)
    assert Evaluator.evaluate(expr, item) == true

    # Invalid conversions are strict (DD-8): garbage raises at the evaluator
    # level; the predicate boundary converts it to no-match
    expr = Code.string_to_quoted!(~s|to_integer(fields["text"])|)

    assert_raise Riffle.Predicate.Dsl.CoercionError, fn ->
      Evaluator.evaluate(expr, item)
    end

    expr = Code.string_to_quoted!(~s|to_float(fields["text"])|)

    assert_raise Riffle.Predicate.Dsl.CoercionError, fn ->
      Evaluator.evaluate(expr, item)
    end
  end

  describe "strict coercion at the predicate boundary (DD-8)" do
    test "failure: a partial numeric parse never matches" do
      {:ok, func} = Evaluator.parse("to_integer(@age) > 30")

      assert func.(Item.new(["age"], ["35abc"])) == false
      assert func.(Item.new(["age"], ["35"])) == true
    end

    test "failure: garbage never fabricates a zero that matches" do
      {:ok, func} = Evaluator.parse("to_integer(@count) == 0")

      assert func.(Item.new(["count"], ["banana"])) == false
      assert func.(Item.new(["count"], ["0"])) == true
    end

    test "failure: implicit comparison coercion requires a full parse" do
      {:ok, func} = Evaluator.parse("@age > 30")

      assert func.(Item.new(["age"], ["35abc"])) == false
      assert func.(Item.new(["age"], ["35"])) == true
    end

    test "failure: to_boolean outside the enumeration never matches" do
      {:ok, func} = Evaluator.parse("to_boolean(@flag)")

      assert func.(Item.new(["flag"], ["banana"])) == false
      assert func.(Item.new(["flag"], ["yes"])) == true
    end
  end

  test "string operation helpers" do
    item = Item.new(["text"], ["hello world"])

    # contains
    expr = Code.string_to_quoted!(~s|contains(fields["text"], "world")|)
    assert Evaluator.evaluate(expr, item) == true

    expr = Code.string_to_quoted!(~s|contains(fields["text"], "goodbye")|)
    assert Evaluator.evaluate(expr, item) == false

    # starts_with
    expr = Code.string_to_quoted!(~s|starts_with(fields["text"], "hello")|)
    assert Evaluator.evaluate(expr, item) == true

    expr = Code.string_to_quoted!(~s|starts_with(fields["text"], "world")|)
    assert Evaluator.evaluate(expr, item) == false

    # ends_with
    expr = Code.string_to_quoted!(~s|ends_with(fields["text"], "world")|)
    assert Evaluator.evaluate(expr, item) == true

    expr = Code.string_to_quoted!(~s|ends_with(fields["text"], "hello")|)
    assert Evaluator.evaluate(expr, item) == false
  end

  test "has_field and has_tag helpers" do
    item = Item.new(["status"], ["active"])
    item = Riffle.Predicate.Item.add_tag(item, :premium)

    # has_field
    expr = Code.string_to_quoted!(~s|has_field("status")|)
    assert Evaluator.evaluate(expr, item) == true

    expr = Code.string_to_quoted!(~s|has_field("nonexistent")|)
    assert Evaluator.evaluate(expr, item) == false

    # has_tag
    expr = Code.string_to_quoted!(~s|has_tag(:premium)|)
    assert Evaluator.evaluate(expr, item) == true

    expr = Code.string_to_quoted!(~s|has_tag(:nonexistent)|)
    assert Evaluator.evaluate(expr, item) == false
  end

  test "metadata access" do
    item = Item.new(["status"], ["active"])
    item = Riffle.Predicate.Item.add_metadata(item, %{count: 42})

    # metadata access
    expr = Code.string_to_quoted!(~s|metadata[:count]|)
    assert Evaluator.evaluate(expr, item) == 42

    expr = Code.string_to_quoted!(~s|metadata.get(:count)|)
    assert Evaluator.evaluate(expr, item) == 42

    expr = Code.string_to_quoted!(~s|metadata[:nonexistent]|)
    assert Evaluator.evaluate(expr, item) == nil
  end

  test "numeric type coercion in comparisons" do
    item = Item.new(["number_string", "number"], ["123", "456"])

    # String to number comparison
    expr = Code.string_to_quoted!(~s|fields["number_string"] == 123|)
    assert Evaluator.evaluate(expr, item) == true

    expr = Code.string_to_quoted!(~s|fields["number_string"] != 456|)
    assert Evaluator.evaluate(expr, item) == true

    expr = Code.string_to_quoted!(~s|fields["number_string"] < 200|)
    assert Evaluator.evaluate(expr, item) == true

    expr = Code.string_to_quoted!(~s|fields["number_string"] > 100|)
    assert Evaluator.evaluate(expr, item) == true

    expr = Code.string_to_quoted!(~s|fields["number_string"] <= 123|)
    assert Evaluator.evaluate(expr, item) == true

    expr = Code.string_to_quoted!(~s|fields["number_string"] >= 123|)
    assert Evaluator.evaluate(expr, item) == true

    # Number to string comparison
    expr = Code.string_to_quoted!(~s|123 == fields["number_string"]|)
    assert Evaluator.evaluate(expr, item) == true
  end

  test "@field shorthand syntax" do
    item = Item.new(["status", "tier", "age"], ["active", "premium", "35"])

    # Simple field access
    expr = Code.string_to_quoted!(~s|@status|)
    assert Evaluator.evaluate(expr, item) == "active"

    # Equality comparison
    expr = Code.string_to_quoted!(~s|@status == "active"|)
    assert Evaluator.evaluate(expr, item) == true

    # Combined expressions
    expr = Code.string_to_quoted!(~s|@status == "active" && @tier == "premium"|)
    assert Evaluator.evaluate(expr, item) == true

    # Nonexistent field
    expr = Code.string_to_quoted!(~s|@nonexistent|)
    assert Evaluator.evaluate(expr, item) == nil

    # With functions
    expr = Code.string_to_quoted!(~s|to_integer(@age) > 30|)
    assert Evaluator.evaluate(expr, item) == true
  end

  test "complex expressions" do
    item = Item.new(["status", "tier", "age", "login_count"], ["active", "premium", "35", "120"])
    item = Riffle.Predicate.Item.add_tag(item, :verified)

    # Using traditional fields["key"] syntax
    complex_expr = """
    (fields["status"] == "active" && to_integer(fields["age"]) > 30) || 
    (fields["tier"] == "premium" && to_integer(fields["login_count"]) > 100)
    """

    expr = Code.string_to_quoted!(complex_expr)
    assert Evaluator.evaluate(expr, item) == true

    # Using @field syntax
    complex_expr2 = """
    (@status == "active" && to_integer(@age) > 30) || 
    (@tier == "premium" && to_integer(@login_count) > 100)
    """

    expr = Code.string_to_quoted!(complex_expr2)
    assert Evaluator.evaluate(expr, item) == true

    # Mixed syntax
    condition_expr = """
    has_field("status") && @status == "active" && has_tag(:verified)
    """

    expr = Code.string_to_quoted!(condition_expr)
    assert Evaluator.evaluate(expr, item) == true
  end
end
