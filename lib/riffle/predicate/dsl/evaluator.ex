defmodule Riffle.Predicate.Dsl.Evaluator do
  @moduledoc """
  Evaluates expression syntax for predicate definitions.

  This module enables the `expr` syntax in predicate definitions, providing a simpler
  way to define predicates without writing full Elixir functions. It parses expressions
  and converts them to executable predicate functions.

  ## Examples

      # Simple equality comparison
      Evaluator.parse(`fields["status"] == "active"`)
      # Or with syntactic sugar
      Evaluator.parse(`@status == "active"`)

      # Numeric comparison
      Evaluator.parse(`fields["age"] > 30`)
      # Or with syntactic sugar
      Evaluator.parse(`@age > 30`)

      # Logical operators
      Evaluator.parse(`fields["status"] == "active" && fields["tier"] == "premium"`)
      # Or with syntactic sugar
      Evaluator.parse(`@status == "active" && @tier == "premium"`)
  """

  alias Riffle.Predicate.Coerce
  alias Riffle.Predicate.Dsl.CoercionError
  alias Riffle.Predicate.Item

  @type expression :: String.t() | term()
  @type parsing_result :: {:ok, function()} | {:error, term()}

  @doc """
  Parses an expression and converts it to a predicate function.

  ## Parameters
    * `expression` - String or quoted expression to parse
    
  ## Returns
    * `{:ok, function}` or `{:error, reason}`

  ## Examples

      iex> alias Riffle.Predicate.Dsl.Evaluator
      iex> alias Riffle.Predicate.Item
      iex> {:ok, func} = Evaluator.parse(quote do: fields["status"] == "active" end)
      iex> is_function(func, 1)
      true
      iex> item = Item.new(["status"], ["active"])
      iex> func.(item)
      true
      
      # Using syntactic sugar with @field
      iex> {:ok, func} = Evaluator.parse(quote do: @status == "active" end)
      iex> item = Item.new(["status"], ["active"])
      iex> func.(item)
      true
  """
  @spec parse(expression()) :: parsing_result()
  def parse(expression) when is_binary(expression) do
    try do
      {:ok, quoted} = Code.string_to_quoted(expression)
      parse(quoted)
    rescue
      e -> {:error, "Failed to parse expression: #{inspect(e)}"}
    end
  end

  def parse(quoted) do
    try do
      {:ok, create_function(quoted)}
    rescue
      e -> {:error, "Failed to create function from expression: #{inspect(e)}"}
    end
  end

  @doc """
  Creates a predicate function from an expression.

  ## Parameters
    * `expr` - The quoted expression to convert
    
  ## Returns
    * A function that takes an item and returns a boolean

  ## Examples

      iex> alias Riffle.Predicate.Dsl.Evaluator
      iex> alias Riffle.Predicate.Item
      iex> func = Evaluator.create_function(quote do: fields["status"] == "active" end)
      iex> item = Item.new(["status"], ["active"])
      iex> func.(item)
      true
      
      # Using @field syntax
      iex> func = Evaluator.create_function(quote do: @status == "active" end)
      iex> item = Item.new(["status"], ["active"])
      iex> func.(item)
      true
  """
  @spec create_function(term()) :: function()
  def create_function(expr) do
    fn item ->
      try do
        evaluate(expr, item)
      rescue
        # DD-8: an explicit coercion on garbage input means the predicate
        # simply does not match -- never a fabricated zero.
        CoercionError -> false
      end
    end
  end

  @doc """
  Evaluates an expression against a specific item.

  ## Parameters
    * `expr` - The quoted expression to evaluate
    * `item` - The item to evaluate against
    
  ## Returns
    * Result of the evaluation (usually a boolean)

  ## Examples

      iex> alias Riffle.Predicate.Dsl.Evaluator
      iex> alias Riffle.Predicate.Item
      iex> item = Item.new(["status", "tier"], ["active", "premium"])
      iex> Evaluator.evaluate(quote do: fields["status"] == "active" end, item)
      true
      iex> Evaluator.evaluate(quote do: fields["tier"] == "basic" end, item)
      false
      
      # Using @field syntax
      iex> Evaluator.evaluate(quote do: @status == "active" end, item)
      true
  """
  @spec evaluate(term(), Item.t()) :: boolean() | term()
  # Handle direct fields access
  def evaluate({:fields, _, [[key]]}, item) when is_binary(key) do
    Map.get(item.fields, key)
  end

  # Handle access syntax: fields["key"]
  def evaluate({{:., _, [Access, :get]}, _, [{:fields, _, _}, key]}, item) when is_binary(key) do
    Map.get(item.fields, key)
  end

  # Handle bracket access syntax
  def evaluate({{:., _, [{:fields, _, _}, :get]}, _, [key]}, item) when is_binary(key) do
    Map.get(item.fields, key)
  end

  # Handle other forms of access syntax
  def evaluate({{:., _, [Access, :get]}, _, [{:fields, _, _}, key]}, item) do
    Map.get(item.fields, to_string(key))
  end

  # Handle @field shorthand syntax
  def evaluate({:@, _, [{field_name, _, nil}]}, item) when is_atom(field_name) do
    field_key = to_string(field_name)
    Map.get(item.fields, field_key)
  end

  # Check if field exists
  def evaluate({:has_field, _, [field]}, item) when is_binary(field) do
    Map.has_key?(item.fields, field)
  end

  # Check if a tag exists
  def evaluate({:has_tag, _, [tag]}, item) when is_atom(tag) do
    tag in item.tags
  end

  # Get metadata
  def evaluate({{:., _, [{:metadata, _, _}, :get]}, _, [key]}, item) when is_atom(key) do
    Map.get(item.metadata, key)
  end

  # Handle metadata access using map syntax: metadata[:key]
  def evaluate({{:., _, [Access, :get]}, _, [{:metadata, _, _}, key]}, item) when is_atom(key) do
    Map.get(item.metadata, key)
  end

  # Type conversion helpers. Strict (DD-8): full parses and the defined
  # truthiness enumeration only; garbage raises CoercionError, which the
  # predicate boundary (create_function/1) converts to no-match.
  def evaluate({:to_integer, _, [expr]}, item) do
    value = evaluate(expr, item)

    case Coerce.to_integer(value) do
      {:ok, integer} ->
        integer

      :error ->
        raise CoercionError,
          message: "to_integer: cannot coerce #{inspect(value)} (full parses only)"
    end
  end

  def evaluate({:to_float, _, [expr]}, item) do
    value = evaluate(expr, item)

    case Coerce.to_float(value) do
      {:ok, float} ->
        float

      :error ->
        raise CoercionError,
          message: "to_float: cannot coerce #{inspect(value)} (full parses only)"
    end
  end

  def evaluate({:to_string, _, [expr]}, item) do
    value = evaluate(expr, item)
    to_string(value)
  end

  def evaluate({:to_boolean, _, [expr]}, item) do
    value = evaluate(expr, item)

    case Coerce.to_boolean(value) do
      {:ok, boolean} ->
        boolean

      :error ->
        raise CoercionError,
          message: "to_boolean: #{inspect(value)} is outside the truthiness enumeration"
    end
  end

  # String operations
  def evaluate({:contains, _, [string, substring]}, item) do
    string_val = evaluate(string, item) |> to_string()
    substring_val = evaluate(substring, item) |> to_string()
    String.contains?(string_val, substring_val)
  end

  def evaluate({:starts_with, _, [string, prefix]}, item) do
    string_val = evaluate(string, item) |> to_string()
    prefix_val = evaluate(prefix, item) |> to_string()
    String.starts_with?(string_val, prefix_val)
  end

  def evaluate({:ends_with, _, [string, suffix]}, item) do
    string_val = evaluate(string, item) |> to_string()
    suffix_val = evaluate(suffix, item) |> to_string()
    String.ends_with?(string_val, suffix_val)
  end

  # Comparison operators. Implicit mixed-type coercion is strict (DD-8): a
  # string compared against a number must parse fully, and a failed parse is
  # simply false -- the comparison is already the boolean boundary.
  def evaluate({:==, _, [left, right]}, item) do
    left_val = evaluate(left, item)
    right_val = evaluate(right, item)

    case {left_val, right_val} do
      {l, r} when is_number(l) and is_binary(r) ->
        case Coerce.to_number(r) do
          {:ok, num} -> l == num
          :error -> false
        end

      {l, r} when is_binary(l) and is_number(r) ->
        case Coerce.to_number(l) do
          {:ok, num} -> num == r
          :error -> false
        end

      {l, r} ->
        l == r
    end
  end

  def evaluate({:!=, _, [left, right]}, item) do
    !evaluate({:==, nil, [left, right]}, item)
  end

  def evaluate({:>, _, [left, right]}, item) do
    left_val = evaluate(left, item)
    right_val = evaluate(right, item)

    case {left_val, right_val} do
      {l, r} when is_number(l) and is_binary(r) ->
        case Coerce.to_number(r) do
          {:ok, num} -> l > num
          :error -> false
        end

      {l, r} when is_binary(l) and is_number(r) ->
        case Coerce.to_number(l) do
          {:ok, num} -> num > r
          :error -> false
        end

      {l, r} when is_number(l) and is_number(r) ->
        l > r

      {l, r} when is_binary(l) and is_binary(r) ->
        l > r

      _ ->
        false
    end
  end

  def evaluate({:<, _, [left, right]}, item) do
    left_val = evaluate(left, item)
    right_val = evaluate(right, item)

    case {left_val, right_val} do
      {l, r} when is_number(l) and is_binary(r) ->
        case Coerce.to_number(r) do
          {:ok, num} -> l < num
          :error -> false
        end

      {l, r} when is_binary(l) and is_number(r) ->
        case Coerce.to_number(l) do
          {:ok, num} -> num < r
          :error -> false
        end

      {l, r} when is_number(l) and is_number(r) ->
        l < r

      {l, r} when is_binary(l) and is_binary(r) ->
        l < r

      _ ->
        false
    end
  end

  def evaluate({:>=, _, [left, right]}, item) do
    evaluate({:>, nil, [left, right]}, item) || evaluate({:==, nil, [left, right]}, item)
  end

  def evaluate({:<=, _, [left, right]}, item) do
    evaluate({:<, nil, [left, right]}, item) || evaluate({:==, nil, [left, right]}, item)
  end

  # Logical operators
  def evaluate({:&&, _, [left, right]}, item) do
    evaluate(left, item) && evaluate(right, item)
  end

  def evaluate({:||, _, [left, right]}, item) do
    evaluate(left, item) || evaluate(right, item)
  end

  def evaluate({:!, _, [expr]}, item) do
    !evaluate(expr, item)
  end

  # Literals and fallbacks
  def evaluate(value, _item)
      when is_binary(value) or is_number(value) or is_boolean(value) or is_nil(value) do
    value
  end

  def evaluate({value, _, nil}, _item) when is_atom(value) do
    value
  end

  def evaluate(other, _item) do
    raise ArgumentError, "Unsupported expression: #{inspect(other)}"
  end
end

defmodule Riffle.Predicate.Dsl.CoercionError do
  @moduledoc """
  Raised when an explicit expr coercion (`to_integer`, `to_float`,
  `to_boolean`) receives input outside the strict contract:
  full parses and the defined truthiness enumeration only.
  `Riffle.Predicate.Dsl.Evaluator.create_function/1` converts it to a
  no-match at the predicate boundary: garbage input never matches.
  """
  defexception [:message]
end
