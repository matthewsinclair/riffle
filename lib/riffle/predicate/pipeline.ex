defmodule Riffle.Predicate.Pipeline do
  @moduledoc """
  Module for composing loops into processing pipelines.

  A pipeline is a sequence of loops that form a processing pipeline. Each item
  flows through the loops in order, potentially being filtered out at any stage.

  ## Examples

      iex> alias Riffle.{Predicate, Predicate.Loop, Predicate.Pipeline, Predicate.Item}
      iex> loop1 = Loop.new(:active, "Active users", [Predicate.new(:active, "Active", fn item -> item.fields["status"] == "active" end)])
      iex> loop2 = Loop.new(:premium, "Premium users", [Predicate.new(:premium, "Premium", fn item -> item.fields["tier"] == "premium" end)])
      iex> pipeline = Pipeline.new(:user_pipeline, "User processing pipeline", [loop1, loop2])
      iex> items = [Item.new(["status", "tier"], ["active", "premium"]), Item.new(["status", "tier"], ["active", "basic"])]
      iex> pipeline |> Pipeline.process(items) |> Enum.to_list() |> length()
      1
  """

  alias Riffle.Predicate.Item
  alias Riffle.Predicate.Loop
  alias Riffle.Predicate.Resolver

  @type t :: %__MODULE__{
          name: atom(),
          description: String.t(),
          loops: [Loop.t()]
        }

  defstruct name: nil, description: "", loops: []

  @doc """
  Creates a new pipeline definition.

  ## Parameters
    * `name` - Name of the pipeline (atom)
    * `description` - Human-readable description
    * `loops` - List of loops

  ## Returns
    * A new Pipeline struct

  ## Examples

      iex> alias Riffle.{Predicate.Loop, Predicate.Pipeline}
      iex> loop = Loop.new(:test, "Test loop", [])
      iex> Pipeline.new(:pipeline, "Processing pipeline", [loop])
      %Pipeline{name: :pipeline, description: "Processing pipeline", loops: [%Loop{name: :test, description: "Test loop", predicates: []}]}
  """
  @spec new(atom(), String.t(), [Loop.t()]) :: t()
  def new(name, description, loops)
      when is_atom(name) and is_binary(description) and is_list(loops) do
    %__MODULE__{name: name, description: description, loops: loops}
  end

  @doc """
  Processes items through all loops in the pipeline.

  For an enumerable of items, returns a stream: each loop filters the stream
  in turn, so only items matching at least one predicate in every loop survive
  (a loop ORs its predicates; the pipeline ANDs its loops).

  For a single `Item`, returns the updated item when it survives every loop,
  or `nil` when a loop filters it out -- being filtered is a domain outcome of
  a filtering engine, not an error. Loops after the filtering one do not run.

  Map-shaped pipelines (macro expansion output, `.pred` definitions) are
  resolved to a fully hydrated `Pipeline` struct first -- through their own
  module context when stamped, else the configured default pipeline -- and
  then processed on the struct path.

  ## Parameters
    * `pipeline` - The pipeline (struct or map shape) to process items through
    * `items` - Enumerable of items, or a single `Item`

  ## Returns
    * Stream of processed items, or (for a single item) `Item.t() | nil`

  ## Examples

      iex> alias Riffle.{Predicate, Predicate.Loop, Predicate.Pipeline, Predicate.Item}
      iex> loop1 = Loop.new(:active, "Active users", [Predicate.new(:active, "Active", fn item -> item.fields["status"] == "active" end)])
      iex> loop2 = Loop.new(:premium, "Premium users", [Predicate.new(:premium, "Premium", fn item -> item.fields["tier"] == "premium" end)])
      iex> pipeline = Pipeline.new(:user_pipeline, "User processing pipeline", [loop1, loop2])
      iex> items = [Item.new(["status", "tier"], ["active", "premium"]), Item.new(["status", "tier"], ["inactive", "premium"])]
      iex> processed = pipeline |> Pipeline.process(items) |> Enum.to_list()
      iex> length(processed)
      1
      iex> hd(processed).tags |> Enum.sort()
      [:active, :premium]
  """
  @spec process(t() | map(), Enumerable.t() | Item.t()) :: Enumerable.t() | Item.t() | nil
  def process(%__MODULE__{loops: loops}, %Item{} = item) do
    loops
    |> Enum.reduce_while({true, item}, fn loop, {true, current_item} ->
      case Loop.process(loop, current_item) do
        {true, updated_item} -> {:cont, {true, updated_item}}
        {false, updated_item} -> {:halt, {false, updated_item}}
      end
    end)
    |> case do
      {true, updated_item} -> updated_item
      {false, _filtered_out} -> nil
    end
  end

  def process(%__MODULE__{loops: loops}, items) do
    Enum.reduce(loops, items, fn loop, stream -> Loop.filter(loop, stream) end)
  end

  def process(%{} = pipeline_map, items_or_item) do
    pipeline_map |> resolve!() |> process(items_or_item)
  end

  @doc """
  Processes a list of raw CSV records through the pipeline.

  Converts CSV records to items and processes them through the pipeline.

  ## Parameters
    * `pipeline` - The pipeline to process records through
    * `header` - List of field names from CSV header
    * `records` - List of lists representing CSV records

  ## Returns
    * Stream of processed items

  ## Examples

      iex> alias Riffle.{Predicate, Predicate.Loop, Predicate.Pipeline, Predicate.Item}
      iex> loop = Loop.new(:active, "Active users", [Predicate.new(:active, "Active", fn item -> item.fields["status"] == "active" end)])
      iex> pipeline = Pipeline.new(:user_pipeline, "User processing pipeline", [loop])
      iex> header = ["id", "status"]
      iex> records = [["1", "active"], ["2", "inactive"]]
      iex> processed = pipeline |> Pipeline.process_csv(header, records) |> Enum.to_list()
      iex> length(processed)
      1
      iex> hd(processed).fields["id"]
      "1"
  """
  @spec process_csv(t(), [String.t()], [[String.t()]]) :: Enumerable.t()
  def process_csv(%__MODULE__{} = pipeline, header, records) do
    items = Enum.map(records, &Item.new(header, &1))
    process(pipeline, items)
  end

  @doc """
  Adds a loop to a pipeline.

  ## Parameters
    * `pipeline` - The pipeline to add the loop to
    * `loop` - The loop to add

  ## Returns
    * Updated pipeline with the new loop

  ## Examples

      iex> alias Riffle.{Predicate.Loop, Predicate.Pipeline}
      iex> pipeline = %Pipeline{loops: []}
      iex> loop = Loop.new(:test, "Test loop", [])
      iex> updated_pipeline = Pipeline.add_loop(pipeline, loop)
      iex> length(updated_pipeline.loops)
      1
  """
  @spec add_loop(t(), Loop.t()) :: t()
  def add_loop(%__MODULE__{} = pipeline, %Loop{} = loop) do
    %{pipeline | loops: [loop | pipeline.loops]}
  end

  # Resolution context: the pipeline's own module when stamped, else the
  # configured default pipeline (handled inside the Resolver). Raises
  # UnresolvedPredicateError rather than processing half-resolved shapes.
  defp resolve!(pipeline_map) do
    Resolver.resolve_pipeline!(Map.get(pipeline_map, :module), pipeline_map)
  end
end
