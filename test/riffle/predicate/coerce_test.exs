defmodule Riffle.Predicate.CoerceTest do
  use ExUnit.Case, async: true
  doctest Riffle.Predicate.Coerce

  alias Riffle.Predicate.Coerce

  describe "to_integer/1" do
    test "success: integers pass through and full string parses convert" do
      assert Coerce.to_integer(42) == {:ok, 42}
      assert Coerce.to_integer("123") == {:ok, 123}
      assert Coerce.to_integer("-7") == {:ok, -7}
    end

    test "failure: partial parses, garbage, and non-integer terms are errors" do
      assert Coerce.to_integer("12abc") == :error
      assert Coerce.to_integer("abc") == :error
      assert Coerce.to_integer("") == :error
      assert Coerce.to_integer("12.5") == :error
      assert Coerce.to_integer(12.5) == :error
      assert Coerce.to_integer(nil) == :error
    end
  end

  describe "to_float/1" do
    test "success: numbers pass through and full string parses convert" do
      assert Coerce.to_float(1.5) == {:ok, 1.5}
      assert Coerce.to_float(3) == {:ok, 3.0}
      assert Coerce.to_float("123.5") == {:ok, 123.5}
      assert Coerce.to_float("123") == {:ok, 123.0}
    end

    test "failure: partial parses, garbage, and non-numeric terms are errors" do
      assert Coerce.to_float("12.5x") == :error
      assert Coerce.to_float("abc") == :error
      assert Coerce.to_float(nil) == :error
      assert Coerce.to_float(:atom) == :error
    end
  end

  describe "to_number/1" do
    test "success: integer strings stay integers, float strings become floats" do
      assert Coerce.to_number("42") == {:ok, 42}
      assert Coerce.to_number("42.5") == {:ok, 42.5}
      assert Coerce.to_number(7) == {:ok, 7}
      assert Coerce.to_number(7.5) == {:ok, 7.5}
    end

    test "failure: partial parses and garbage are errors" do
      assert Coerce.to_number("42abc") == :error
      assert Coerce.to_number("banana") == :error
      assert Coerce.to_number(nil) == :error
    end
  end

  describe "to_text/1" do
    test "success: binaries pass through and numbers stringify" do
      assert Coerce.to_text("abc") == {:ok, "abc"}
      assert Coerce.to_text(42) == {:ok, "42"}
      assert Coerce.to_text(1.5) == {:ok, "1.5"}
    end

    test "failure: nil, atoms, and other terms are errors -- absent data never becomes text" do
      assert Coerce.to_text(nil) == :error
      assert Coerce.to_text(:atom) == :error
      assert Coerce.to_text([]) == :error
    end
  end

  describe "to_boolean/1" do
    test "success: booleans, 1/0, and the enumerated strings convert (case-insensitive)" do
      assert Coerce.to_boolean(true) == {:ok, true}
      assert Coerce.to_boolean(false) == {:ok, false}
      assert Coerce.to_boolean(1) == {:ok, true}
      assert Coerce.to_boolean(0) == {:ok, false}
      assert Coerce.to_boolean("TRUE") == {:ok, true}
      assert Coerce.to_boolean("Yes") == {:ok, true}
      assert Coerce.to_boolean("t") == {:ok, true}
      assert Coerce.to_boolean("on") == {:ok, true}
      assert Coerce.to_boolean("off") == {:ok, false}
      assert Coerce.to_boolean("n") == {:ok, false}
      assert Coerce.to_boolean("F") == {:ok, false}
    end

    test "failure: anything outside the enumeration is an error, never accidental truth" do
      assert Coerce.to_boolean("banana") == :error
      assert Coerce.to_boolean(2) == :error
      assert Coerce.to_boolean(nil) == :error
      assert Coerce.to_boolean([]) == :error
    end
  end

  describe "truthy?/1 and falsey?/1" do
    test "invariant: garbage is neither truthy nor falsey" do
      assert Coerce.truthy?("yes") == true
      assert Coerce.truthy?("no") == false
      assert Coerce.truthy?("banana") == false
      assert Coerce.falsey?("no") == true
      assert Coerce.falsey?("yes") == false
      assert Coerce.falsey?("banana") == false
      assert Coerce.falsey?(nil) == false
    end
  end
end
