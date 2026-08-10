defmodule Riffle.Predicate.Loop do
  @moduledoc """
  Module for organizing predicates into processing groups.

  A loop is a collection of predicates that are applied to each item in sequence.
  Items that match at least one predicate continue to the next loop; items that
  don't match any predicates are filtered out.

  ## Examples

      iex> alias Riffle.{Predicate, Predicate.Loop, Predicate.Item}
      iex> predicates = [
      ...>   Predicate.new(:active, "Active users", fn item -> item.fields["status"] == "active" end),
      ...>   Predicate.new(:premium, "Premium users", fn item -> item.fields["tier"] == "premium" end)
      ...> ]
      iex> loop = Loop.new(:user_filter, "Filters active or premium users", predicates)
      iex> items = [Item.new(["status", "tier"], ["active", "basic"]), Item.new(["status", "tier"], ["inactive", "basic"])]
      iex> loop |> Loop.filter(items) |> Enum.to_list() |> length()
      1
  """

  alias Riffle.Predicate
  alias Riffle.Predicate.Item
  alias Riffle.Predicate.Resolver

  @type t :: %__MODULE__{
          name: atom(),
          description: String.t(),
          predicates: [Predicate.predicate_definition()]
        }

  defstruct name: nil, description: "", predicates: []

  @doc """
  Creates a new loop definition.

  ## Parameters
    * `name` - Name of the loop (atom)
    * `description` - Human-readable description
    * `predicates` - List of predicate definitions

  ## Returns
    * A new Loop struct

  ## Examples

      iex> alias Riffle.{Predicate, Predicate.Loop}
      iex> predicates = [Predicate.new(:active, "Active users", fn _item -> true end)]
      iex> loop = Loop.new(:user_filter, "Filters users", predicates)
      iex> loop.name == :user_filter and loop.description == "Filters users" and length(loop.predicates) == 1
      true
  """
  @spec new(atom(), String.t(), [Predicate.predicate_definition()]) :: t()
  def new(name, description, predicates)
      when is_atom(name) and is_binary(description) and is_list(predicates) do
    %__MODULE__{name: name, description: description, predicates: predicates}
  end

  @doc """
  Processes an item through all predicates in the loop.

  Returns a tuple with a boolean indicating if any predicate matched and the
  updated item with any tags and metadata from matched predicates.

  ## Parameters
    * `loop` - The loop to process the item through
    * `item` - The item to process

  ## Returns
    * Tuple of {matched, updated_item}

  ## Examples

      iex> alias Riffle.{Predicate, Predicate.Loop, Predicate.Item}
      iex> predicates = [Predicate.new(:active, "Active users", fn item -> item.fields["status"] == "active" end)]
      iex> loop = Loop.new(:user_filter, "Filters users", predicates)
      iex> item = Item.new(["status"], ["active"])
      iex> {matched, updated_item} = Loop.process(loop, item)
      iex> matched
      true
      iex> updated_item.tags
      [:active]
  """
  @spec process(t() | map(), Item.t()) :: {boolean(), Item.t()}
  def process(%__MODULE__{predicates: predicates}, %Item{} = item) do
    Enum.reduce(predicates, {false, item}, fn predicate, {matched, current_item} ->
      {predicate_matched, updated_item} = Predicate.evaluate(predicate, current_item)
      {matched || predicate_matched, updated_item}
    end)
  end

  # Map-shaped loops (macro expansion output, .pred definitions) resolve to a
  # Loop struct first, then take the one struct path above.
  def process(%{} = loop_map, %Item{} = item) do
    loop_map |> resolve!() |> process(item)
  end

  @doc """
  Filters a stream of items using the loop's predicates.

  Returns a stream of items that matched at least one predicate in the loop.

  ## Parameters
    * `loop` - The loop to filter items with
    * `items` - Enumerable of items to filter

  ## Returns
    * Stream of filtered and updated items

  ## Examples

      iex> alias Riffle.{Predicate, Predicate.Loop, Predicate.Item}
      iex> predicates = [Predicate.new(:active, "Active users", fn item -> item.fields["status"] == "active" end)]
      iex> loop = Loop.new(:user_filter, "Filters users", predicates)
      iex> items = [Item.new(["status"], ["active"]), Item.new(["status"], ["inactive"])]
      iex> filtered = loop |> Loop.filter(items) |> Enum.to_list()
      iex> length(filtered)
      1
      iex> hd(filtered).tags
      [:active]
  """
  @spec filter(t() | map(), Enumerable.t()) :: Enumerable.t()
  def filter(%__MODULE__{} = loop, items) do
    items
    |> Stream.map(&process(loop, &1))
    |> Stream.filter(fn {matched, _item} -> matched end)
    |> Stream.map(fn {_matched, item} -> item end)
  end

  # Map-shaped loops resolve ONCE before streaming, then share the cached
  # process/2 entry point with the single-item path.
  def filter(%{} = loop_map, items) do
    loop_map |> resolve!() |> filter(items)
  end

  @doc """
  Adds a predicate to a loop.

  ## Parameters
    * `loop` - The loop to add the predicate to
    * `predicate` - The predicate to add

  ## Returns
    * Updated loop with the new predicate

  ## Examples

      iex> alias Riffle.{Predicate, Predicate.Loop}
      iex> loop = %Loop{predicates: []}
      iex> predicate = Predicate.new(:active, "Active users", fn _item -> true end)
      iex> updated_loop = Loop.add_predicate(loop, predicate)
      iex> length(updated_loop.predicates)
      1
  """
  @spec add_predicate(t(), Predicate.predicate_definition()) :: t()
  def add_predicate(%__MODULE__{} = loop, predicate) do
    %{loop | predicates: [predicate | loop.predicates]}
  end

  # Resolution context: the loop's own module when stamped, else the
  # configured default pipeline (handled inside the Resolver). Raises
  # UnresolvedPredicateError; a reference must never silently become an
  # always-false predicate that filters every item with no signal.
  defp resolve!(loop_map) do
    Resolver.resolve_loop!(Map.get(loop_map, :module), loop_map)
  end
end
