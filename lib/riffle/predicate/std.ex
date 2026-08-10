defmodule Riffle.Predicate.STD do
  @moduledoc """
  Module alias helper for Riffle.Predicate.StandardLib.

  This module provides a convenient way to access all StandardLib functionality
  through a single `use` statement.

  ## Usage

  ```elixir
  defmodule MyPredicates do
    use Riffle.Predicate.STD

    def check_subscription(item) do
      STD.Boolean.is_false("subscribed").(item)
    end
  end
  ```
  """

  defmacro __using__(_opts) do
    quote do
      alias Riffle.Predicate.StandardLib, as: STD
    end
  end
end
