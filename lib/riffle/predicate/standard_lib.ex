defmodule Riffle.Predicate.StandardLib do
  @moduledoc """
  A library of standard, reusable predicates for common operations.

  This module provides a collection of predefined predicates that can be used
  in your predicate processing pipelines. These predicates are organized into
  categories for different types of operations:

  - Text: String comparison and manipulation
  - Numeric: Numeric comparisons and operations
  - Boolean: Boolean/logical operations
  - Collection: Operations on collections of values
  - Date: Date/time comparisons and operations

  ## Usage

  The standard predicates are functions that return predicates (higher-order functions).
  All functions in the library return a function that takes an Item and returns a boolean.

  ### 1. In runtime-loaded .pred files via call syntax:

  ```elixir
  predicate(:premium_user, "User has a premium account") do
    call &Riffle.Predicate.StandardLib.Text.equals/2, ["tier", "premium"]
  end
  ```

  ### 2. In compile-time DSL modules:

  ```elixir
  defmodule MyPredicates do
    use Riffle.Predicate.Dsl.Macro
    alias Riffle.Predicate.StandardLib, as: STD

    defpredicate :premium_user, "User has a premium account" do
      STD.Text.equals("tier", "premium")
    end
  end
  ```

  ### 3. Directly in Loop definitions:

  ```elixir
  alias Riffle.Predicate.StandardLib, as: STD
  alias Riffle.Predicate.Loop

  loop = Loop.new()
  |> Loop.add_predicate(:premium_user, STD.Text.equals("tier", "premium"))
  |> Loop.add_predicate(:active_user, STD.Text.equals("status", "active"))
  ```

  ### 4. Combined using logical operators:

  ```elixir
  alias Riffle.Predicate.StandardLib, as: STD

  premium_and_active = STD.all([
    STD.Text.equals("tier", "premium"),
    STD.Text.equals("status", "active")
  ])
  ```
  """

  defmodule Text do
    @moduledoc """
    Predicates for text/string operations.

    These predicates handle string comparisons, pattern matching,
    and other text-based operations. All functions return predicate functions
    that can be used directly in Loops and other predicate-based contexts.
    """

    alias Riffle.Predicate.Item

    @doc """
    Creates a predicate function that checks if a field equals a value.

    ## Parameters
      * `field` - The name of the field to check
      * `value` - The value to compare against

    ## Returns
      * A function that takes an item and returns a boolean

    ## Examples

        iex> alias Riffle.Predicate.StandardLib.Text
        iex> alias Riffle.Predicate.Item
        iex> predicate = Text.equals("status", "active")
        iex> item1 = Item.new(["status"], ["active"])
        iex> item2 = Item.new(["status"], ["inactive"])
        iex> predicate.(item1)
        true
        iex> predicate.(item2)
        false

    ## Usage in a Loop

        loop = Loop.new()
        |> Loop.add_predicate(:active_users, Text.equals("status", "active"))
    """
    @spec equals(String.t(), String.t()) :: (Item.t() -> boolean())
    def equals(field, value) when is_binary(field) and is_binary(value) do
      fn item -> Item.get_field(item, field) == value end
    end

    @doc """
    Creates a predicate function that checks if a field doesn't equal a value.

    ## Parameters
      * `field` - The name of the field to check
      * `value` - The value to compare against

    ## Returns
      * A function that takes an item and returns a boolean

    ## Examples

        iex> alias Riffle.Predicate.StandardLib.Text
        iex> alias Riffle.Predicate.Item
        iex> predicate = Text.not_equals("status", "inactive")
        iex> item1 = Item.new(["status"], ["active"])
        iex> item2 = Item.new(["status"], ["inactive"])
        iex> predicate.(item1)
        true
        iex> predicate.(item2)
        false
    """
    @spec not_equals(String.t(), String.t()) :: (Item.t() -> boolean())
    def not_equals(field, value) when is_binary(field) and is_binary(value) do
      fn item -> Item.get_field(item, field) != value end
    end

    @doc """
    Creates a predicate function that checks if a field contains a substring.

    ## Parameters
      * `field` - The name of the field to check
      * `substring` - The substring to look for

    ## Returns
      * A function that takes an item and returns a boolean

    ## Examples

        iex> alias Riffle.Predicate.StandardLib.Text
        iex> alias Riffle.Predicate.Item
        iex> predicate = Text.contains("description", "premium")
        iex> item1 = Item.new(["description"], ["This is a premium account"])
        iex> item2 = Item.new(["description"], ["This is a free account"])
        iex> predicate.(item1)
        true
        iex> predicate.(item2)
        false
    """
    @spec contains(String.t(), String.t()) :: (Item.t() -> boolean())
    def contains(field, substring) when is_binary(field) and is_binary(substring) do
      fn item ->
        value = Item.get_field(item, field)
        is_binary(value) and String.contains?(value, substring)
      end
    end

    @doc """
    Creates a predicate function that checks if a field starts with a prefix.

    ## Parameters
      * `field` - The name of the field to check
      * `prefix` - The prefix to check for

    ## Returns
      * A function that takes an item and returns a boolean

    ## Examples

        iex> alias Riffle.Predicate.StandardLib.Text
        iex> alias Riffle.Predicate.Item
        iex> predicate = Text.starts_with("code", "ABC")
        iex> item1 = Item.new(["code"], ["ABC123"])
        iex> item2 = Item.new(["code"], ["XYZ456"])
        iex> predicate.(item1)
        true
        iex> predicate.(item2)
        false
    """
    @spec starts_with(String.t(), String.t()) :: (Item.t() -> boolean())
    def starts_with(field, prefix) when is_binary(field) and is_binary(prefix) do
      fn item ->
        value = Item.get_field(item, field)
        is_binary(value) and String.starts_with?(value, prefix)
      end
    end

    @doc """
    Creates a predicate function that checks if a field ends with a suffix.

    ## Parameters
      * `field` - The name of the field to check
      * `suffix` - The suffix to check for

    ## Returns
      * A function that takes an item and returns a boolean

    ## Examples

        iex> alias Riffle.Predicate.StandardLib.Text
        iex> alias Riffle.Predicate.Item
        iex> predicate = Text.ends_with("email", "example.com")
        iex> item1 = Item.new(["email"], ["user@example.com"])
        iex> item2 = Item.new(["email"], ["user@gmail.com"])
        iex> predicate.(item1)
        true
        iex> predicate.(item2)
        false
    """
    @spec ends_with(String.t(), String.t()) :: (Item.t() -> boolean())
    def ends_with(field, suffix) when is_binary(field) and is_binary(suffix) do
      fn item ->
        value = Item.get_field(item, field)
        is_binary(value) and String.ends_with?(value, suffix)
      end
    end

    @doc """
    Creates a predicate function that checks if a field matches a regular expression.

    ## Parameters
      * `field` - The name of the field to check
      * `pattern` - The regular expression pattern to match

    ## Returns
      * A function that takes an item and returns a boolean

    ## Examples

        iex> alias Riffle.Predicate.StandardLib.Text
        iex> alias Riffle.Predicate.Item
        iex> predicate = Text.matches("email", ~r/@example\\.com$/)
        iex> item1 = Item.new(["email"], ["user@example.com"])
        iex> item2 = Item.new(["email"], ["user@gmail.com"])
        iex> predicate.(item1)
        true
        iex> predicate.(item2)
        false
    """
    @spec matches(String.t(), Regex.t()) :: (Item.t() -> boolean())
    def matches(field, pattern) when is_binary(field) and is_struct(pattern, Regex) do
      fn item ->
        value = Item.get_field(item, field)
        is_binary(value) and Regex.match?(pattern, value)
      end
    end
  end

  defmodule Numeric do
    @moduledoc """
    Predicates for numeric comparisons and operations.

    These predicates handle numeric comparisons, range checks,
    and other number-based operations. All functions return predicate functions
    that can be used directly in Loops and other predicate-based contexts.
    """

    alias Riffle.Predicate.Item

    @doc """
    Creates a predicate function that checks if a field equals a number.

    Attempts to parse the field value as a number before comparison.

    ## Parameters
      * `field` - The name of the field to check
      * `value` - The number to compare against

    ## Returns
      * A function that takes an item and returns a boolean

    ## Examples

        iex> alias Riffle.Predicate.StandardLib.Numeric
        iex> alias Riffle.Predicate.Item
        iex> predicate = Numeric.equal_to("age", 30)
        iex> item1 = Item.new(["age"], ["30"])
        iex> item2 = Item.new(["age"], ["31"])
        iex> predicate.(item1)
        true
        iex> predicate.(item2)
        false
    """
    @spec equal_to(String.t(), number()) :: (Item.t() -> boolean())
    def equal_to(field, value) when is_binary(field) and is_number(value) do
      fn item ->
        case Riffle.Predicate.Coerce.to_number(Item.get_field(item, field)) do
          {:ok, num} -> num == value
          _ -> false
        end
      end
    end

    @doc """
    Creates a predicate function that checks if a field is greater than a number.

    Attempts to parse the field value as a number before comparison.

    ## Parameters
      * `field` - The name of the field to check
      * `value` - The number to compare against

    ## Returns
      * A function that takes an item and returns a boolean

    ## Examples

        iex> alias Riffle.Predicate.StandardLib.Numeric
        iex> alias Riffle.Predicate.Item
        iex> predicate = Numeric.greater_than("age", 30)
        iex> item1 = Item.new(["age"], ["35"])
        iex> item2 = Item.new(["age"], ["25"])
        iex> predicate.(item1)
        true
        iex> predicate.(item2)
        false
    """
    @spec greater_than(String.t(), number()) :: (Item.t() -> boolean())
    def greater_than(field, value) when is_binary(field) and is_number(value) do
      fn item ->
        case Riffle.Predicate.Coerce.to_number(Item.get_field(item, field)) do
          {:ok, num} -> num > value
          _ -> false
        end
      end
    end

    @doc """
    Creates a predicate function that checks if a field is less than a number.

    Attempts to parse the field value as a number before comparison.

    ## Parameters
      * `field` - The name of the field to check
      * `value` - The number to compare against

    ## Returns
      * A function that takes an item and returns a boolean

    ## Examples

        iex> alias Riffle.Predicate.StandardLib.Numeric
        iex> alias Riffle.Predicate.Item
        iex> predicate = Numeric.less_than("age", 30)
        iex> item1 = Item.new(["age"], ["25"])
        iex> item2 = Item.new(["age"], ["35"])
        iex> predicate.(item1)
        true
        iex> predicate.(item2)
        false
    """
    @spec less_than(String.t(), number()) :: (Item.t() -> boolean())
    def less_than(field, value) when is_binary(field) and is_number(value) do
      fn item ->
        case Riffle.Predicate.Coerce.to_number(Item.get_field(item, field)) do
          {:ok, num} -> num < value
          _ -> false
        end
      end
    end

    @doc """
    Creates a predicate function that checks if a field is greater than or equal to a number.

    Attempts to parse the field value as a number before comparison.

    ## Parameters
      * `field` - The name of the field to check
      * `value` - The number to compare against

    ## Returns
      * A function that takes an item and returns a boolean

    ## Examples

        iex> alias Riffle.Predicate.StandardLib.Numeric
        iex> alias Riffle.Predicate.Item
        iex> predicate = Numeric.greater_than_or_equal_to("age", 30)
        iex> item1 = Item.new(["age"], ["30"])
        iex> item2 = Item.new(["age"], ["29"])
        iex> predicate.(item1)
        true
        iex> predicate.(item2)
        false
    """
    @spec greater_than_or_equal_to(String.t(), number()) :: (Item.t() -> boolean())
    def greater_than_or_equal_to(field, value) when is_binary(field) and is_number(value) do
      fn item ->
        case Riffle.Predicate.Coerce.to_number(Item.get_field(item, field)) do
          {:ok, num} -> num >= value
          _ -> false
        end
      end
    end

    @doc """
    Creates a predicate function that checks if a field is less than or equal to a number.

    Attempts to parse the field value as a number before comparison.

    ## Parameters
      * `field` - The name of the field to check
      * `value` - The number to compare against

    ## Returns
      * A function that takes an item and returns a boolean

    ## Examples

        iex> alias Riffle.Predicate.StandardLib.Numeric
        iex> alias Riffle.Predicate.Item
        iex> predicate = Numeric.less_than_or_equal_to("age", 30)
        iex> item1 = Item.new(["age"], ["30"])
        iex> item2 = Item.new(["age"], ["31"])
        iex> predicate.(item1)
        true
        iex> predicate.(item2)
        false
    """
    @spec less_than_or_equal_to(String.t(), number()) :: (Item.t() -> boolean())
    def less_than_or_equal_to(field, value) when is_binary(field) and is_number(value) do
      fn item ->
        case Riffle.Predicate.Coerce.to_number(Item.get_field(item, field)) do
          {:ok, num} -> num <= value
          _ -> false
        end
      end
    end

    @doc """
    Creates a predicate function that checks if a field is between two specified numbers (inclusive).

    Attempts to parse the field value as a number before comparison.

    ## Parameters
      * `field` - The name of the field to check
      * `min` - The minimum value (inclusive)
      * `max` - The maximum value (inclusive)

    ## Returns
      * A function that takes an item and returns a boolean

    ## Examples

        iex> alias Riffle.Predicate.StandardLib.Numeric
        iex> alias Riffle.Predicate.Item
        iex> predicate = Numeric.between("age", 18, 30)
        iex> item1 = Item.new(["age"], ["25"])
        iex> item2 = Item.new(["age"], ["35"])
        iex> predicate.(item1)
        true
        iex> predicate.(item2)
        false
    """
    @spec between(String.t(), number(), number()) :: (Item.t() -> boolean())
    def between(field, min, max)
        when is_binary(field) and is_number(min) and is_number(max) and min <= max do
      fn item ->
        case Riffle.Predicate.Coerce.to_number(Item.get_field(item, field)) do
          {:ok, num} -> num >= min and num <= max
          _ -> false
        end
      end
    end

    @doc """
    Creates a predicate function that checks if a field's value is a valid number.

    ## Parameters
      * `field` - The name of the field to check

    ## Returns
      * A function that takes an item and returns a boolean

    ## Examples

        iex> alias Riffle.Predicate.StandardLib.Numeric
        iex> alias Riffle.Predicate.Item
        iex> predicate = Numeric.valid_number("value")
        iex> item1 = Item.new(["value"], ["123"])
        iex> item2 = Item.new(["value"], ["abc"])
        iex> predicate.(item1)
        true
        iex> predicate.(item2)
        false
    """
    @spec valid_number(String.t()) :: (Item.t() -> boolean())
    def valid_number(field) when is_binary(field) do
      fn item ->
        case Riffle.Predicate.Coerce.to_number(Item.get_field(item, field)) do
          {:ok, _} -> true
          _ -> false
        end
      end
    end
  end

  defmodule Boolean do
    @moduledoc """
    Predicates for boolean operations.

    These predicates handle boolean checks, logical operations,
    and existence checks. All functions return predicate functions
    that can be used directly in Loops and other predicate-based contexts.
    """

    alias Riffle.Predicate.Item

    @doc """
    Creates a predicate function that checks if a field's value is "true", "yes", "1", etc. (case-insensitive).

    ## Parameters
      * `field` - The name of the field to check

    ## Returns
      * A function that takes an item and returns a boolean

    ## Examples

        iex> alias Riffle.Predicate.StandardLib.Boolean
        iex> alias Riffle.Predicate.Item
        iex> predicate = Boolean.is_true("verified")
        iex> item1 = Item.new(["verified"], ["true"])
        iex> item2 = Item.new(["verified"], ["YES"])
        iex> item3 = Item.new(["verified"], ["0"])
        iex> predicate.(item1)
        true
        iex> predicate.(item2)
        true
        iex> predicate.(item3)
        false
    """
    @spec is_true(String.t()) :: (Item.t() -> boolean())
    def is_true(field) when is_binary(field) do
      fn item ->
        item |> Item.get_field(field) |> Riffle.Predicate.Coerce.truthy?()
      end
    end

    @doc """
    Creates a predicate function that checks if a field's value is "false", "no", "0", etc. (case-insensitive).

    ## Parameters
      * `field` - The name of the field to check

    ## Returns
      * A function that takes an item and returns a boolean

    ## Examples

        iex> alias Riffle.Predicate.StandardLib.Boolean
        iex> alias Riffle.Predicate.Item
        iex> predicate = Boolean.is_false("verified")
        iex> item1 = Item.new(["verified"], ["false"])
        iex> item2 = Item.new(["verified"], ["NO"])
        iex> item3 = Item.new(["verified"], ["1"])
        iex> predicate.(item1)
        true
        iex> predicate.(item2)
        true
        iex> predicate.(item3)
        false
    """
    @spec is_false(String.t()) :: (Item.t() -> boolean())
    def is_false(field) when is_binary(field) do
      fn item ->
        item |> Item.get_field(field) |> Riffle.Predicate.Coerce.falsey?()
      end
    end

    @doc """
    Creates a predicate function that checks if a field exists and has a non-empty value.

    ## Parameters
      * `field` - The name of the field to check

    ## Returns
      * A function that takes an item and returns a boolean

    ## Examples

        iex> alias Riffle.Predicate.StandardLib.Boolean
        iex> alias Riffle.Predicate.Item
        iex> predicate = Boolean.has_value("email")
        iex> item1 = Item.new(["email"], ["user@example.com"])
        iex> item2 = Item.new(["email"], [""])
        iex> item3 = Item.new(["phone"], ["555-1234"])
        iex> predicate.(item1)
        true
        iex> predicate.(item2)
        false
        iex> predicate.(item3)
        false
    """
    @spec has_value(String.t()) :: (Item.t() -> boolean())
    def has_value(field) when is_binary(field) do
      fn item ->
        value = Item.get_field(item, field)
        is_binary(value) and value != ""
      end
    end

    @doc """
    Creates a predicate function that checks if a field is missing or has an empty value.

    ## Parameters
      * `field` - The name of the field to check

    ## Returns
      * A function that takes an item and returns a boolean

    ## Examples

        iex> alias Riffle.Predicate.StandardLib.Boolean
        iex> alias Riffle.Predicate.Item
        iex> predicate = Boolean.is_empty("email")
        iex> item1 = Item.new(["email"], ["user@example.com"])
        iex> item2 = Item.new(["email"], [""])
        iex> predicate.(item1)
        false
        iex> predicate.(item2)
        true
        iex> predicate.(Item.new(["phone"], ["555-1234"]))
        true
    """
    @spec is_empty(String.t()) :: (Item.t() -> boolean())
    def is_empty(field) when is_binary(field) do
      fn item ->
        value = Item.get_field(item, field)
        value == nil or value == ""
      end
    end
  end

  defmodule Collection do
    @moduledoc """
    Predicates for collection operations.

    These predicates handle operations on collections, arrays, or
    comma-separated values in strings. All functions return predicate functions
    that can be used directly in Loops and other predicate-based contexts.
    """

    alias Riffle.Predicate.Item

    @doc """
    Creates a predicate function that checks if a field's comma-separated value 
    contains any of the specified values.

    ## Parameters
      * `field` - The name of the field to check
      * `values` - The list of values to check for

    ## Returns
      * A function that takes an item and returns a boolean

    ## Examples

        iex> alias Riffle.Predicate.StandardLib.Collection
        iex> alias Riffle.Predicate.Item
        iex> predicate = Collection.contains_any("roles", ["admin", "manager"])
        iex> item1 = Item.new(["roles"], ["admin,editor,viewer"])
        iex> item2 = Item.new(["roles"], ["developer,tester"])
        iex> predicate.(item1)
        true
        iex> predicate.(item2)
        false
    """
    @spec contains_any(String.t(), [String.t()]) :: (Item.t() -> boolean())
    def contains_any(field, values) when is_binary(field) and is_list(values) do
      fn item ->
        field_value = Item.get_field(item, field)
        items = split_values(field_value)
        Enum.any?(values, &Enum.member?(items, &1))
      end
    end

    @doc """
    Creates a predicate function that checks if a field's comma-separated value 
    contains all of the specified values.

    ## Parameters
      * `field` - The name of the field to check
      * `values` - The list of values to check for

    ## Returns
      * A function that takes an item and returns a boolean

    ## Examples

        iex> alias Riffle.Predicate.StandardLib.Collection
        iex> alias Riffle.Predicate.Item
        iex> predicate = Collection.contains_all("roles", ["admin", "editor"])
        iex> item1 = Item.new(["roles"], ["admin,editor,viewer"])
        iex> item2 = Item.new(["roles"], ["admin,manager"])
        iex> predicate.(item1)
        true
        iex> predicate.(item2)
        false
    """
    @spec contains_all(String.t(), [String.t()]) :: (Item.t() -> boolean())
    def contains_all(field, values) when is_binary(field) and is_list(values) do
      fn item ->
        field_value = Item.get_field(item, field)
        items = split_values(field_value)
        Enum.all?(values, &Enum.member?(items, &1))
      end
    end

    @doc """
    Creates a predicate function that checks if a field's comma-separated value 
    has at least a specified number of items.

    ## Parameters
      * `field` - The name of the field to check
      * `count` - The minimum number of items required

    ## Returns
      * A function that takes an item and returns a boolean

    ## Examples

        iex> alias Riffle.Predicate.StandardLib.Collection
        iex> alias Riffle.Predicate.Item
        iex> predicate = Collection.count_at_least("roles", 3)
        iex> item1 = Item.new(["roles"], ["admin,editor,viewer"])
        iex> item2 = Item.new(["roles"], ["admin,editor"])
        iex> predicate.(item1)
        true
        iex> predicate.(item2)
        false
    """
    @spec count_at_least(String.t(), integer()) :: (Item.t() -> boolean())
    def count_at_least(field, count)
        when is_binary(field) and is_integer(count) and count >= 0 do
      fn item ->
        field_value = Item.get_field(item, field)
        items = split_values(field_value)
        length(items) >= count
      end
    end

    @doc """
    Creates a predicate function that checks if a field's comma-separated value 
    has at most a specified number of items.

    ## Parameters
      * `field` - The name of the field to check
      * `count` - The maximum number of items allowed

    ## Returns
      * A function that takes an item and returns a boolean

    ## Examples

        iex> alias Riffle.Predicate.StandardLib.Collection
        iex> alias Riffle.Predicate.Item
        iex> predicate = Collection.count_at_most("roles", 3)
        iex> item1 = Item.new(["roles"], ["admin,editor,viewer"])
        iex> item2 = Item.new(["roles"], ["admin,editor,viewer,manager"])
        iex> predicate.(item1)
        true
        iex> predicate.(item2)
        false
    """
    @spec count_at_most(String.t(), integer()) :: (Item.t() -> boolean())
    def count_at_most(field, count)
        when is_binary(field) and is_integer(count) and count >= 0 do
      fn item ->
        field_value = Item.get_field(item, field)
        items = split_values(field_value)
        length(items) <= count
      end
    end

    # Helper function to split comma-separated values
    defp split_values(nil), do: []

    defp split_values(value) when is_binary(value) do
      value
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.filter(&(&1 != ""))
    end

    defp split_values(_), do: []
  end

  defmodule Date do
    @moduledoc """
    Predicates for date and time operations.

    These predicates handle date comparisons, time ranges,
    and other date/time related operations. All functions return predicate functions
    that can be used directly in Loops and other predicate-based contexts.
    """

    alias Riffle.Predicate.Item

    @doc """
    Creates a predicate function that checks if a field's date is before the specified date.

    ## Parameters
      * `field` - The name of the field to check
      * `date` - The date to compare against (ISO 8601 string or Date/DateTime struct)

    ## Returns
      * A function that takes an item and returns a boolean

    ## Examples

        iex> alias Riffle.Predicate.StandardLib.Date
        iex> alias Riffle.Predicate.Item
        iex> today = Elixir.Date.utc_today() |> Elixir.Date.to_iso8601()
        iex> yesterday = Elixir.Date.utc_today() |> Elixir.Date.add(-1) |> Elixir.Date.to_iso8601()
        iex> tomorrow = Elixir.Date.utc_today() |> Elixir.Date.add(1) |> Elixir.Date.to_iso8601()
        iex> predicate = Date.before("created_at", today)
        iex> item1 = Item.new(["created_at"], [yesterday])
        iex> item2 = Item.new(["created_at"], [tomorrow])
        iex> predicate.(item1)
        true
        iex> predicate.(item2)
        false
    """
    @spec before(String.t(), any()) :: (Item.t() -> boolean())
    def before(field, date) when is_binary(field) do
      comparison_date = normalize_date(date)

      fn item ->
        field_value = Item.get_field(item, field)

        case parse_date(field_value) do
          {:ok, date_value} -> Elixir.Date.compare(date_value, comparison_date) == :lt
          _ -> false
        end
      end
    end

    @doc """
    Creates a predicate function that checks if a field's date is after the specified date.

    ## Parameters
      * `field` - The name of the field to check
      * `date` - The date to compare against (ISO 8601 string or Date/DateTime struct)

    ## Returns
      * A function that takes an item and returns a boolean

    ## Examples

        iex> alias Riffle.Predicate.StandardLib.Date
        iex> alias Riffle.Predicate.Item
        iex> today = Elixir.Date.utc_today() |> Elixir.Date.to_iso8601()
        iex> yesterday = Elixir.Date.utc_today() |> Elixir.Date.add(-1) |> Elixir.Date.to_iso8601()
        iex> tomorrow = Elixir.Date.utc_today() |> Elixir.Date.add(1) |> Elixir.Date.to_iso8601()
        iex> predicate = Date.date_after("created_at", today)
        iex> item1 = Item.new(["created_at"], [tomorrow])
        iex> item2 = Item.new(["created_at"], [yesterday])
        iex> predicate.(item1)
        true
        iex> predicate.(item2)
        false
    """
    @spec date_after(String.t(), any()) :: (Item.t() -> boolean())
    def date_after(field, date) when is_binary(field) do
      comparison_date = normalize_date(date)

      fn item ->
        field_value = Item.get_field(item, field)

        case parse_date(field_value) do
          {:ok, date_value} -> Elixir.Date.compare(date_value, comparison_date) == :gt
          _ -> false
        end
      end
    end

    @doc """
    Creates a predicate function that checks if a field's date is between two specified dates (inclusive).

    ## Parameters
      * `field` - The name of the field to check
      * `start_date` - The start date (inclusive)
      * `end_date` - The end date (inclusive)

    ## Returns
      * A function that takes an item and returns a boolean

    ## Examples

        iex> alias Riffle.Predicate.StandardLib.Date
        iex> alias Riffle.Predicate.Item
        iex> today = Elixir.Date.utc_today() |> Elixir.Date.to_iso8601()
        iex> yesterday = Elixir.Date.utc_today() |> Elixir.Date.add(-1) |> Elixir.Date.to_iso8601()
        iex> tomorrow = Elixir.Date.utc_today() |> Elixir.Date.add(1) |> Elixir.Date.to_iso8601()
        iex> predicate = Date.between("created_at", yesterday, tomorrow)
        iex> item1 = Item.new(["created_at"], [today])
        iex> item2 = Item.new(["created_at"], [Elixir.Date.utc_today() |> Elixir.Date.add(2) |> Elixir.Date.to_iso8601()])
        iex> predicate.(item1)
        true
        iex> predicate.(item2)
        false
    """
    @spec between(String.t(), any(), any()) :: (Item.t() -> boolean())
    def between(field, start_date, end_date) when is_binary(field) do
      start = normalize_date(start_date)
      end_d = normalize_date(end_date)

      fn item ->
        field_value = Item.get_field(item, field)

        case parse_date(field_value) do
          {:ok, date_value} ->
            Elixir.Date.compare(date_value, start) in [:eq, :gt] and
              Elixir.Date.compare(date_value, end_d) in [:eq, :lt]

          _ ->
            false
        end
      end
    end

    @doc """
    Creates a predicate function that checks if a field's date is within the last n days.

    ## Parameters
      * `field` - The name of the field to check
      * `days` - The number of days to check

    ## Returns
      * A function that takes an item and returns a boolean

    ## Examples

        iex> alias Riffle.Predicate.StandardLib.Date
        iex> alias Riffle.Predicate.Item
        iex> yesterday = Elixir.Date.utc_today() |> Elixir.Date.add(-1) |> Elixir.Date.to_iso8601()
        iex> last_week = Elixir.Date.utc_today() |> Elixir.Date.add(-7) |> Elixir.Date.to_iso8601()
        iex> predicate = Date.within_last_days("created_at", 3)
        iex> item1 = Item.new(["created_at"], [yesterday])
        iex> item2 = Item.new(["created_at"], [last_week])
        iex> predicate.(item1)
        true
        iex> predicate.(item2)
        false
    """
    @spec within_last_days(String.t(), integer()) :: (Item.t() -> boolean())
    def within_last_days(field, days)
        when is_binary(field) and is_integer(days) and days > 0 do
      # The window is fixed at construction, like the sibling date
      # predicates: a cached evaluation must not flip when the wall-clock
      # day rolls over mid-TTL.
      today = Elixir.Date.utc_today()
      days_ago = Elixir.Date.add(today, -days)

      fn item ->
        field_value = Item.get_field(item, field)

        case parse_date(field_value) do
          {:ok, date_value} ->
            Elixir.Date.compare(date_value, days_ago) in [:eq, :gt] and
              Elixir.Date.compare(date_value, today) in [:eq, :lt]

          _ ->
            false
        end
      end
    end

    # Helper functions for date handling
    defp normalize_date(%Elixir.Date{} = date), do: date
    defp normalize_date(%Elixir.DateTime{} = datetime), do: Elixir.DateTime.to_date(datetime)

    defp normalize_date(date_string) when is_binary(date_string) do
      case parse_date(date_string) do
        {:ok, date} ->
          date

        _ ->
          # The comparison date is author-supplied configuration, resolved at
          # predicate construction -- a typo must fail there, not silently
          # become "today" on every evaluation.
          raise ArgumentError,
                "invalid comparison date #{inspect(date_string)}: " <>
                  "expected an ISO 8601 date or datetime"
      end
    end

    defp parse_date(nil), do: {:error, :nil_value}
    defp parse_date(%Elixir.Date{} = date), do: {:ok, date}
    defp parse_date(%Elixir.DateTime{} = datetime), do: {:ok, Elixir.DateTime.to_date(datetime)}

    defp parse_date(date_string) when is_binary(date_string) do
      # Try parsing as Date
      case Elixir.Date.from_iso8601(date_string) do
        {:ok, date} ->
          {:ok, date}

        _ ->
          # Try parsing as DateTime
          case Elixir.DateTime.from_iso8601(date_string) do
            {:ok, datetime, _} -> {:ok, Elixir.DateTime.to_date(datetime)}
            _ -> {:error, :invalid_date_format}
          end
      end
    end

    defp parse_date(_), do: {:error, :invalid_value}
  end

  @doc """
  Creates a predicate function that combines multiple predicates with a logical AND.

  Returns a function that returns true only if all predicates match.

  ## Parameters
    * `predicates` - List of predicate functions

  ## Returns
    * A function that takes an item and returns a boolean
    
  ## Examples

      iex> alias Riffle.Predicate.StandardLib, as: STD
      iex> alias Riffle.Predicate.Item
      iex> active_pred = STD.Text.equals("status", "active")
      iex> premium_pred = STD.Text.equals("tier", "premium")
      iex> combined_pred = STD.all([active_pred, premium_pred])
      iex> item1 = Item.new(["status", "tier"], ["active", "premium"])
      iex> item2 = Item.new(["status", "tier"], ["active", "basic"])
      iex> combined_pred.(item1)
      true
      iex> combined_pred.(item2)
      false
  """
  @spec all([function()]) :: (Riffle.Predicate.Item.t() -> boolean())
  def all(predicates) when is_list(predicates) do
    fn item -> Enum.all?(predicates, fn pred -> pred.(item) end) end
  end

  @doc """
  Creates a predicate function that combines multiple predicates with a logical OR.

  Returns a function that returns true if any predicate matches.

  ## Parameters
    * `predicates` - List of predicate functions

  ## Returns
    * A function that takes an item and returns a boolean
    
  ## Examples

      iex> alias Riffle.Predicate.StandardLib, as: STD
      iex> alias Riffle.Predicate.Item
      iex> active_pred = STD.Text.equals("status", "active")
      iex> premium_pred = STD.Text.equals("tier", "premium")
      iex> combined_pred = STD.any([active_pred, premium_pred])
      iex> item1 = Item.new(["status", "tier"], ["inactive", "premium"])
      iex> item2 = Item.new(["status", "tier"], ["inactive", "basic"])
      iex> combined_pred.(item1)
      true
      iex> combined_pred.(item2)
      false
  """
  @spec any([function()]) :: (Riffle.Predicate.Item.t() -> boolean())
  def any(predicates) when is_list(predicates) do
    fn item -> Enum.any?(predicates, fn pred -> pred.(item) end) end
  end

  @doc """
  Creates a predicate function that negates another predicate.

  Returns a function that returns true if the predicate doesn't match.

  ## Parameters
    * `predicate` - The predicate function to negate

  ## Returns
    * A function that takes an item and returns a boolean
    
  ## Examples

      iex> alias Riffle.Predicate.StandardLib, as: STD
      iex> alias Riffle.Predicate.Item
      iex> active_pred = STD.Text.equals("status", "active")
      iex> not_active = STD.not_pred(active_pred)
      iex> item1 = Item.new(["status"], ["inactive"])
      iex> item2 = Item.new(["status"], ["active"])
      iex> not_active.(item1)
      true
      iex> not_active.(item2)
      false
  """
  @spec not_pred(function()) :: (Riffle.Predicate.Item.t() -> boolean())
  def not_pred(predicate) when is_function(predicate, 1) do
    fn item -> !predicate.(item) end
  end

  @doc """
  Creates a predicate function ensuring no predicates match (logical NOR).

  Returns a function that returns true only if none of the predicates match.

  ## Parameters
    * `predicates` - List of predicate functions

  ## Returns
    * A function that takes an item and returns a boolean
    
  ## Examples

      iex> alias Riffle.Predicate.StandardLib, as: STD
      iex> alias Riffle.Predicate.Item
      iex> active_pred = STD.Text.equals("status", "active")
      iex> premium_pred = STD.Text.equals("tier", "premium")
      iex> neither = STD.none([active_pred, premium_pred])
      iex> item1 = Item.new(["status", "tier"], ["pending", "basic"])
      iex> item2 = Item.new(["status", "tier"], ["active", "basic"])
      iex> neither.(item1)
      true
      iex> neither.(item2)
      false
  """
  @spec none([function()]) :: (Riffle.Predicate.Item.t() -> boolean())
  def none(predicates) when is_list(predicates) do
    fn item -> not Enum.any?(predicates, fn pred -> pred.(item) end) end
  end
end
