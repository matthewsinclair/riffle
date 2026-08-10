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
    {:ok, quoted} = Code.string_to_quoted(expression)
    parse(quoted)
  rescue
    e -> {:error, "Failed to parse expression: #{inspect(e)}"}
  end

  def parse(quoted) do
    {:ok, create_function(quoted)}
  rescue
    e -> {:error, "Failed to create function from expression: #{inspect(e)}"}
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

  # Type conversion helpers. Strict (DD-8): full parses, real text, and the
  # defined truthiness enumeration only; garbage raises CoercionError, which
  # the predicate boundary (create_function/1) converts to no-match.
  def evaluate({:to_integer, _, [expr]}, item), do: coerce!(:to_integer, evaluate(expr, item))
  def evaluate({:to_float, _, [expr]}, item), do: coerce!(:to_float, evaluate(expr, item))
  def evaluate({:to_string, _, [expr]}, item), do: coerce!(:to_text, evaluate(expr, item))
  def evaluate({:to_boolean, _, [expr]}, item), do: coerce!(:to_boolean, evaluate(expr, item))

  # String operations. Operands are implicit coercions: a missing field or
  # non-text value never matches (StandardLib.Text parity) -- it must never
  # glide to "" and positively match absent data.
  def evaluate({:contains, _, [string, substring]}, item) do
    text_compare(string, substring, item, &String.contains?/2)
  end

  def evaluate({:starts_with, _, [string, prefix]}, item) do
    text_compare(string, prefix, item, &String.starts_with?/2)
  end

  def evaluate({:ends_with, _, [string, suffix]}, item) do
    text_compare(string, suffix, item, &String.ends_with?/2)
  end

  # Comparison operators. The mixed-type arms share one coercion ladder
  # (coerced_compare/3); same-type and nil handling stay per-operator --
  # equality is total, ordering is not. A missing field equals nothing, not
  # even another missing field.
  def evaluate({:==, _, [left, right]}, item) do
    left_val = evaluate(left, item)
    right_val = evaluate(right, item)

    case coerced_compare(&==/2, left_val, right_val) do
      {:ok, result} -> result
      :pass when is_nil(left_val) or is_nil(right_val) -> false
      :pass -> left_val == right_val
    end
  end

  def evaluate({:!=, _, [left, right]}, item) do
    not evaluate({:==, nil, [left, right]}, item)
  end

  def evaluate({:>, _, [left, right]}, item) do
    left_val = evaluate(left, item)
    right_val = evaluate(right, item)

    case coerced_compare(&>/2, left_val, right_val) do
      {:ok, result} -> result
      :pass when is_number(left_val) and is_number(right_val) -> left_val > right_val
      :pass when is_binary(left_val) and is_binary(right_val) -> left_val > right_val
      :pass -> false
    end
  end

  def evaluate({:<, _, [left, right]}, item) do
    left_val = evaluate(left, item)
    right_val = evaluate(right, item)

    case coerced_compare(&</2, left_val, right_val) do
      {:ok, result} -> result
      :pass when is_number(left_val) and is_number(right_val) -> left_val < right_val
      :pass when is_binary(left_val) and is_binary(right_val) -> left_val < right_val
      :pass -> false
    end
  end

  def evaluate({:>=, _, [left, right]}, item) do
    evaluate({:>, nil, [left, right]}, item) || evaluate({:==, nil, [left, right]}, item)
  end

  def evaluate({:<=, _, [left, right]}, item) do
    evaluate({:<, nil, [left, right]}, item) || evaluate({:==, nil, [left, right]}, item)
  end

  # Logical operators. Operands go through the Coerce truthiness enumeration
  # (DD-8) -- raw Elixir truthiness would make any unenumerated string (and
  # `!` on a missing field) silently match.
  def evaluate({:&&, _, [left, right]}, item) do
    boolean_operand!(evaluate(left, item)) and boolean_operand!(evaluate(right, item))
  end

  def evaluate({:||, _, [left, right]}, item) do
    boolean_operand!(evaluate(left, item)) or boolean_operand!(evaluate(right, item))
  end

  def evaluate({:!, _, [expr]}, item) do
    not boolean_operand!(evaluate(expr, item))
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

  # The one explicit-coercion boundary: every to_* helper goes through here.
  defp coerce!(kind, value) do
    case apply_coercion(kind, value) do
      {:ok, coerced} ->
        coerced

      :error ->
        raise CoercionError,
          message: "#{kind}: cannot coerce #{inspect(value)} under the strict contract (DD-8)"
    end
  end

  defp apply_coercion(:to_integer, value), do: Coerce.to_integer(value)
  defp apply_coercion(:to_float, value), do: Coerce.to_float(value)
  defp apply_coercion(:to_text, value), do: Coerce.to_text(value)
  defp apply_coercion(:to_boolean, value), do: Coerce.to_boolean(value)

  # Text operands are implicit coercions: non-text (including a missing
  # field's nil) is simply no-match at this boolean boundary.
  defp text_compare(left, right, item, op) do
    with {:ok, left_text} <- Coerce.to_text(evaluate(left, item)),
         {:ok, right_text} <- Coerce.to_text(evaluate(right, item)) do
      op.(left_text, right_text)
    else
      :error -> false
    end
  end

  # The one implicit mixed-type comparison ladder (DD-8): a string against a
  # number must parse fully, and a failed parse is false at this boolean
  # boundary -- never a fabricated value that matches.
  defp coerced_compare(op, left, right) when is_number(left) and is_binary(right) do
    case Coerce.to_number(right) do
      {:ok, number} -> {:ok, op.(left, number)}
      :error -> {:ok, false}
    end
  end

  defp coerced_compare(op, left, right) when is_binary(left) and is_number(right) do
    case Coerce.to_number(left) do
      {:ok, number} -> {:ok, op.(number, right)}
      :error -> {:ok, false}
    end
  end

  defp coerced_compare(_op, _left, _right), do: :pass

  defp boolean_operand!(value) do
    case Coerce.to_boolean(value) do
      {:ok, boolean} ->
        boolean

      :error ->
        raise CoercionError,
          message:
            "logical operator operand #{inspect(value)} is outside the truthiness " <>
              "enumeration -- compare explicitly or use to_boolean/1"
    end
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
