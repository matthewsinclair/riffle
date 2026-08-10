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
  # Handle proper Loop structs
  def process(%__MODULE__{predicates: predicates}, %Item{} = item) do
    Enum.reduce(predicates, {false, item}, fn predicate, {matched, current_item} ->
      {predicate_matched, updated_item} = Predicate.evaluate(predicate, current_item)
      {matched || predicate_matched, updated_item}
    end)
  end

  # Handle loop maps from macro expansion
  def process(%{predicates: predicates}, %Item{} = item) when is_list(predicates) do
    Enum.reduce(predicates, {false, item}, fn predicate, {matched, current_item} ->
      {predicate_matched, updated_item} = Predicate.evaluate(predicate, current_item)
      {matched || predicate_matched, updated_item}
    end)
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
  # Handle proper Loop structs
  def filter(%__MODULE__{} = loop, items) do
    # Create a processing stream that applies predicates to each item
    result_stream =
      Stream.map(items, fn item ->
        # Apply predicates directly to ensure they're evaluated
        {matched, updated_item} =
          Enum.reduce(loop.predicates, {false, item}, fn predicate,
                                                         {matched_so_far, current_item} ->
            # Use direct evaluation for every item
            {this_matched, updated_item} =
              Riffle.Predicate.evaluate_direct(predicate, current_item)

            # Combine results - match if ANY predicate matches
            {matched_so_far || this_matched, updated_item}
          end)

        {matched, updated_item}
      end)
      |> Stream.filter(fn {matched, _} -> matched end)
      |> Stream.map(fn {_, item} -> item end)

    # Return the resulting stream
    result_stream
  end

  # Handle loop maps (common when working with macro-generated data)
  def filter(%{name: name, description: description, predicates: predicates} = loop_map, items)
      when is_list(predicates) do
    # Try to see if we can access any available module context
    module = Map.get(loop_map, :module)

    # Process predicates to ensure they're all fully evaluated predicates
    processed_predicates =
      Enum.map(predicates, fn
        # Predicate references resolve through the loop's module context when
        # present, else the configured default pipeline. Resolution failure
        # raises: a reference that silently became an always-false predicate
        # used to filter every item downstream with no signal.
        %{name: pred_name, inline: false} when not is_nil(module) ->
          resolve_reference!(module, pred_name)

        %{name: pred_name, inline: false} ->
          case Riffle.Predicate.default_pipeline() do
            nil ->
              raise Riffle.Predicate.UnresolvedPredicateError,
                message:
                  "cannot resolve predicate reference #{inspect(pred_name)}: " <>
                    "the loop has no module context and no default pipeline " <>
                    "is configured (config :riffle, :default_pipeline)"

            default_module ->
              resolve_reference!(default_module, pred_name)
          end

        # For predicates with body but no function, create the function
        %{name: pred_name, description: pred_desc, body: body} ->
          function = Riffle.Predicate.create(body)
          Riffle.Predicate.new(pred_name, pred_desc || "", function)

        # Already a proper predicate definition
        predicate = %{function: function} when is_function(function, 1) ->
          predicate

        other ->
          # Just pass it through - it will likely fail later with a clear error
          other
      end)

    # Convert to a proper Loop struct
    loop = %__MODULE__{
      name: name,
      description: description || "",
      predicates: processed_predicates
    }

    # Then filter using the proper struct
    filter(loop, items)
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

  @doc """
  Alias for new/3 for compatibility with DSL modules.
  """
  @spec create(atom(), [Predicate.predicate_definition()]) :: t()
  def create(name, predicates) when is_atom(name) and is_list(predicates) do
    new(name, "", predicates)
  end

  @doc """
  Alias for new/3 for compatibility with DSL modules.
  """
  @spec create(atom(), String.t(), [Predicate.predicate_definition()]) :: t()
  def create(name, description, predicates)
      when is_atom(name) and is_binary(description) and is_list(predicates) do
    new(name, description, predicates)
  end

  # A predicate reference either resolves to a real definition or fails loudly
  # with the reason; there is no silent always-false fallback.
  defp resolve_reference!(module, pred_name) do
    cond do
      not Code.ensure_loaded?(module) ->
        raise Riffle.Predicate.UnresolvedPredicateError,
          message:
            "cannot resolve predicate #{inspect(pred_name)}: " <>
              "module #{inspect(module)} cannot be loaded"

      not function_exported?(module, :get_predicate, 1) ->
        raise Riffle.Predicate.UnresolvedPredicateError,
          message:
            "cannot resolve predicate #{inspect(pred_name)}: " <>
              "#{inspect(module)} does not export get_predicate/1"

      true ->
        case module.get_predicate(pred_name) do
          nil ->
            raise Riffle.Predicate.UnresolvedPredicateError,
              message:
                "cannot resolve predicate #{inspect(pred_name)}: " <>
                  "#{inspect(module)} has no such predicate"

          predicate_def ->
            predicate_def
        end
    end
  end
end
