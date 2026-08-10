defmodule Riffle.Predicate.Dsl.STD do
  @moduledoc """
  DSL-specific interface to Riffle.Predicate.StandardLib.

  This module provides simplified access to StandardLib functions for use in DSL contexts.
  It forwards all calls to the appropriate StandardLib modules while maintaining the
  predicate-factory pattern.
  """

  alias Riffle.Predicate.StandardLib

  defmodule Text do
    @moduledoc "DSL-specific interface to Riffle.Predicate.StandardLib.Text"

    defdelegate equals(field, value), to: StandardLib.Text
    defdelegate not_equals(field, value), to: StandardLib.Text
    defdelegate contains(field, substring), to: StandardLib.Text
    defdelegate starts_with(field, prefix), to: StandardLib.Text
    defdelegate ends_with(field, suffix), to: StandardLib.Text
    defdelegate matches(field, pattern), to: StandardLib.Text
  end

  defmodule Numeric do
    @moduledoc "DSL-specific interface to Riffle.Predicate.StandardLib.Numeric"

    defdelegate equal_to(field, value), to: StandardLib.Numeric
    defdelegate greater_than(field, value), to: StandardLib.Numeric
    defdelegate less_than(field, value), to: StandardLib.Numeric
    defdelegate greater_than_or_equal_to(field, value), to: StandardLib.Numeric
    defdelegate less_than_or_equal_to(field, value), to: StandardLib.Numeric
    defdelegate between(field, min, max), to: StandardLib.Numeric
    defdelegate valid_number(field), to: StandardLib.Numeric
  end

  defmodule Boolean do
    @moduledoc "DSL-specific interface to Riffle.Predicate.StandardLib.Boolean"

    defdelegate is_true(field), to: StandardLib.Boolean
    defdelegate is_false(field), to: StandardLib.Boolean
    defdelegate has_value(field), to: StandardLib.Boolean
    defdelegate is_empty(field), to: StandardLib.Boolean
  end

  defmodule Collection do
    @moduledoc "DSL-specific interface to Riffle.Predicate.StandardLib.Collection"

    defdelegate contains_any(field, values), to: StandardLib.Collection
    defdelegate contains_all(field, values), to: StandardLib.Collection
    defdelegate count_at_least(field, count), to: StandardLib.Collection
    defdelegate count_at_most(field, count), to: StandardLib.Collection
  end

  defmodule Date do
    @moduledoc "DSL-specific interface to Riffle.Predicate.StandardLib.Date"

    defdelegate before(field, date), to: StandardLib.Date
    defdelegate date_after(field, date), to: StandardLib.Date
    defdelegate between(field, start_date, end_date), to: StandardLib.Date
    defdelegate within_last_days(field, days), to: StandardLib.Date
  end

  defdelegate all(predicates), to: StandardLib
  defdelegate any(predicates), to: StandardLib
  defdelegate not_pred(predicate), to: StandardLib
  defdelegate none(predicates), to: StandardLib
end
