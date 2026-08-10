defmodule Riffle.Predicate.Coerce do
  @moduledoc """
  The canonical coercion contract for the predicate engine: strict by default.

  Numeric coercion accepts full parses only -- `"12abc"` is an error, never
  `12` -- and truthiness is a defined enumeration, never accidental. Failures
  are tagged (`:error`); what a failed coercion MEANS (no-match, raise, skip)
  is decided by the caller at its own boundary.

  Consumed by `Riffle.Predicate.Dsl.Evaluator` (explicit expr coercions and
  implicit comparison coercion) and `Riffle.Predicate.StandardLib` (numeric
  and boolean predicates). There is no other coercion path.

  Truthy strings: #{inspect(~w(true yes y 1 on t))}. Falsey strings:
  #{inspect(~w(false no n 0 off f))}. Matching is case-insensitive. The
  integers `1` and `0` mirror their string forms; all other numbers are
  errors.
  """

  @truthy ~w(true yes y 1 on t)
  @falsey ~w(false no n 0 off f)

  @doc """
  Coerces a value to an integer. Integers pass through; strings must parse
  fully.

  ## Examples

      iex> Riffle.Predicate.Coerce.to_integer("123")
      {:ok, 123}
      iex> Riffle.Predicate.Coerce.to_integer("12abc")
      :error
  """
  @spec to_integer(term()) :: {:ok, integer()} | :error
  def to_integer(value) when is_integer(value), do: {:ok, value}

  def to_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} -> {:ok, integer}
      _partial_or_error -> :error
    end
  end

  def to_integer(_other), do: :error

  @doc """
  Coerces a value to a float. Numbers pass through (integers widen); strings
  must parse fully.

  ## Examples

      iex> Riffle.Predicate.Coerce.to_float("123.5")
      {:ok, 123.5}
      iex> Riffle.Predicate.Coerce.to_float("12.5x")
      :error
  """
  @spec to_float(term()) :: {:ok, float()} | :error
  def to_float(value) when is_float(value), do: {:ok, value}
  def to_float(value) when is_integer(value), do: {:ok, value * 1.0}

  def to_float(value) when is_binary(value) do
    case Float.parse(value) do
      {float, ""} -> {:ok, float}
      _partial_or_error -> :error
    end
  end

  def to_float(_other), do: :error

  @doc """
  Coerces a value to a number for comparisons: integer strings stay integers,
  float strings become floats, numbers pass through.

  ## Examples

      iex> Riffle.Predicate.Coerce.to_number("42")
      {:ok, 42}
      iex> Riffle.Predicate.Coerce.to_number("42.5")
      {:ok, 42.5}
      iex> Riffle.Predicate.Coerce.to_number("42abc")
      :error
  """
  @spec to_number(term()) :: {:ok, number()} | :error
  def to_number(value) when is_number(value), do: {:ok, value}

  def to_number(value) when is_binary(value) do
    case to_integer(value) do
      {:ok, integer} -> {:ok, integer}
      :error -> to_float(value)
    end
  end

  def to_number(_other), do: :error

  @doc """
  Coerces a value to text. Binaries pass through; numbers stringify; anything
  else -- including nil -- is an error, so absent data never becomes `""`.

  ## Examples

      iex> Riffle.Predicate.Coerce.to_text("abc")
      {:ok, "abc"}
      iex> Riffle.Predicate.Coerce.to_text(42)
      {:ok, "42"}
      iex> Riffle.Predicate.Coerce.to_text(nil)
      :error
  """
  @spec to_text(term()) :: {:ok, String.t()} | :error
  def to_text(value) when is_binary(value), do: {:ok, value}
  def to_text(value) when is_number(value), do: {:ok, to_string(value)}
  def to_text(_other), do: :error

  @doc """
  Coerces a value to a boolean via the defined enumeration. Booleans pass
  through; `1`/`0` mirror their string forms; strings match case-insensitively.

  ## Examples

      iex> Riffle.Predicate.Coerce.to_boolean("Yes")
      {:ok, true}
      iex> Riffle.Predicate.Coerce.to_boolean("banana")
      :error
  """
  @spec to_boolean(term()) :: {:ok, boolean()} | :error
  def to_boolean(value) when is_boolean(value), do: {:ok, value}
  def to_boolean(1), do: {:ok, true}
  def to_boolean(0), do: {:ok, false}

  def to_boolean(value) when is_binary(value) do
    case String.downcase(value) do
      down when down in @truthy -> {:ok, true}
      down when down in @falsey -> {:ok, false}
      _outside_enumeration -> :error
    end
  end

  def to_boolean(_other), do: :error

  @doc """
  True only for the truthy enumeration. Garbage is not truthy.

  ## Examples

      iex> Riffle.Predicate.Coerce.truthy?("on")
      true
      iex> Riffle.Predicate.Coerce.truthy?("banana")
      false
  """
  @spec truthy?(term()) :: boolean()
  def truthy?(value) do
    case to_boolean(value) do
      {:ok, result} -> result
      :error -> false
    end
  end

  @doc """
  True only for the falsey enumeration. Garbage is not falsey either.

  ## Examples

      iex> Riffle.Predicate.Coerce.falsey?("off")
      true
      iex> Riffle.Predicate.Coerce.falsey?("banana")
      false
  """
  @spec falsey?(term()) :: boolean()
  def falsey?(value) do
    case to_boolean(value) do
      {:ok, result} -> not result
      :error -> false
    end
  end
end
