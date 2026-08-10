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

  alias Riffle.Predicate.Loop
  alias Riffle.Predicate.Item

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

  Returns a stream of items that have been processed through all loops.
  Only items that match at least one predicate in each loop continue to the next loop.

  ## Parameters
    * `pipeline` - The pipeline to process items through
    * `items` - Enumerable of items to process

  ## Returns
    * Stream of processed items

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
  @spec process(t() | map(), Enumerable.t() | Item.t()) :: Enumerable.t() | Item.t()
  # Handle a single Item directly
  def process(%__MODULE__{loops: loops}, %Item{} = item) do
    # Process the item directly through each loop without using streams
    Enum.reduce(loops, {true, item}, fn loop, {continue, current_item} ->
      if continue do
        {matched, updated_item} = Loop.process(loop, current_item)
        {matched, updated_item}
      else
        {continue, current_item}
      end
    end)
    |> case do
      {true, updated_item} -> updated_item
      # Item was filtered out
      {false, _} -> nil
    end
  end

  # Handle Enumerable items with Pipeline struct
  def process(%__MODULE__{loops: loops}, items) do
    # Apply each loop in sequence, accumulating the filtering effects
    result_stream =
      Enum.reduce(loops, items, fn loop, stream ->
        Loop.filter(loop, stream)
      end)

    # Return the resulting stream
    result_stream
  end

  # Handle pipeline maps with single Item
  def process(%{loops: loops, name: pipeline_name, module: module}, %Item{} = item)
      when is_list(loops) and is_atom(module) do
    # Create a temporary Pipeline struct with the module and process with it
    # First add module to each loop
    loops_with_module =
      Enum.map(loops, fn loop ->
        case loop do
          loop_map when is_map(loop_map) -> Map.put(loop_map, :module, module)
          other -> other
        end
      end)

    process(
      %__MODULE__{
        name: pipeline_name,
        loops: loops_with_module
      },
      item
    )
  end

  def process(%{loops: loops, name: pipeline_name} = pipeline, %Item{} = item)
      when is_list(loops) do
    # Resolution context: the pipeline's own module, else the configured
    # default (config :riffle, :default_pipeline). The engine knows no
    # pattern-layer module or pipeline names.
    module = Map.get(pipeline, :module) || Riffle.Predicate.default_pipeline()

    if module do
      process(%{loops: loops, name: pipeline_name, module: module}, item)
    else
      # Create a temporary Pipeline struct and process with it
      process(%__MODULE__{loops: loops}, item)
    end
  end

  # Handle pipeline maps with Enumerable items
  def process(%{loops: loops, name: _pipeline_name, module: module}, items)
      when is_list(loops) and is_atom(module) do
    # Here we have access to the module, so we can properly resolve loop references
    # Process each loop more directly to ensure predicates are evaluated
    result_stream =
      Enum.reduce(loops, items, fn loop, stream ->
        # Get loop module context for proper resolution
        loop_with_module =
          case loop do
            # Ensure the module info is passed along
            loop_map when is_map(loop_map) -> Map.put(loop_map, :module, module)
            other -> other
          end

        # Now filter using the loop with module context
        Loop.filter(loop_with_module, stream)
      end)

    # Return the resulting stream
    result_stream
  end

  # Handle pipeline maps with Enumerable items when no module is explicitly provided
  def process(%{loops: loops, name: pipeline_name} = pipeline, items) when is_list(loops) do
    # Resolution context: the pipeline's own module, else the configured
    # default (config :riffle, :default_pipeline). The engine knows no
    # pattern-layer module or pipeline names.
    module = Map.get(pipeline, :module) || Riffle.Predicate.default_pipeline()

    # If we found a module, use the version that includes it
    if module do
      process(%{loops: loops, name: pipeline_name, module: module}, items)
    else
      # Fallback to the original non-module version
      # Process each loop more directly to ensure predicates are evaluated
      result_stream =
        Enum.reduce(loops, items, fn loop, stream ->
          # This handles both Loop structs and map-based loop descriptions

          # First convert loop maps to Loop structs if needed
          processed_loop =
            case loop do
              %Loop{} ->
                loop

              %{name: name, description: description, predicates: predicates} ->
                # Process predicates to ensure they're fully formed
                processed_predicates =
                  Enum.map(predicates, fn pred ->
                    case pred do
                      %{name: pred_name, description: pred_desc, body: body} ->
                        function = Riffle.Predicate.create(body)
                        Riffle.Predicate.new(pred_name, pred_desc || "", function)

                      # Already a proper predicate definition
                      %{name: _pred_name, function: _} ->
                        pred

                      other ->
                        other
                    end
                  end)

                # Create a proper Loop struct
                %Loop{
                  name: name,
                  description: description || "",
                  predicates: processed_predicates
                }

              other ->
                raise "Unrecognized loop format: #{inspect(other)}"
            end

          # Now filter using the proper Loop struct
          Loop.filter(processed_loop, stream)
        end)

      # Return the resulting stream
      result_stream
    end
  end

  @doc """
  Alias for process/2 for compatibility with DSL modules.
  """
  @spec filter(t(), Enumerable.t()) :: Enumerable.t()
  def filter(stream, items) do
    process(stream, items)
  end

  @doc """
  Alias for new/3 for compatibility with DSL modules.
  """
  @spec create(atom(), [Loop.t()]) :: t()
  def create(name, loops) when is_atom(name) and is_list(loops) do
    new(name, "", loops)
  end

  @doc """
  Alias for new/3 for compatibility with DSL modules.
  """
  @spec create(atom(), String.t(), [Loop.t()]) :: t()
  def create(name, description, loops)
      when is_atom(name) and is_binary(description) and is_list(loops) do
    new(name, description, loops)
  end

  @doc """
  Hydrates a pipeline definition from a DSL module into a fully executable pipeline.

  Takes a pipeline definition (typically obtained from a module using the Predicate DSL)
  and a module containing the predicate implementations, and produces a fully hydrated
  pipeline with all predicate references resolved.

  ## Parameters
    * `pipeline_def` - The pipeline definition to hydrate
    * `module` - The module containing predicate implementations to resolve references

  ## Returns
    * A fully hydrated Pipeline struct ready for execution

  ## Examples
      iex> alias Riffle.{Predicate, Predicate.Loop, Predicate.Pipeline, Predicate.Item}
      iex> defmodule TestPredicateModule do
      ...>   def get_predicate(:is_active), do: Predicate.new(:is_active, "Active items", fn item -> item.fields["status"] == "active" end)
      ...>   def get_loop(:active_loop), do: Loop.new(:active_loop, "Active items loop", [%{name: :is_active, inline: false}])
      ...> end
      iex> pipeline_def = %{name: :test_pipeline, description: "Test pipeline", loops: [%{name: :active_loop, inline: false}]}
      iex> hydrated = Pipeline.hydrate_pipeline(pipeline_def, TestPredicateModule)
      iex> items = [Item.new(["status"], ["active"]), Item.new(["status"], ["inactive"])]
      iex> processed = Pipeline.process(hydrated, items) |> Enum.to_list()
      iex> length(processed)
      1
      iex> hd(processed).fields["status"]
      "active"
  """
  @spec hydrate_pipeline(map(), module()) :: t()
  def hydrate_pipeline(pipeline_def, module) do
    # Hydrate all the loops in the pipeline
    hydrated_loops =
      Enum.map(pipeline_def.loops, fn loop_ref ->
        hydrate_loop(loop_ref, module)
      end)

    # Create a pipeline with the hydrated loops
    %__MODULE__{
      name: pipeline_def.name,
      description: pipeline_def.description || "",
      loops: hydrated_loops
    }
  end

  # Hydrates a loop definition or reference into a fully executable Loop struct
  defp hydrate_loop(loop_ref, module) do
    loop_def =
      case loop_ref do
        # It's already a proper Loop struct
        %Loop{} = loop ->
          loop

        # It's a reference to a loop by name
        %{name: name, inline: false} ->
          apply(module, :get_loop, [name])

        # It's an inline loop definition
        %{name: name, description: description, predicates: predicates} ->
          %{
            name: name,
            description: description || "",
            predicates: predicates
          }

        # Unknown format
        _ ->
          raise "Unrecognized loop reference format: #{inspect(loop_ref)}"
      end

    # Now hydrate all the predicates in the loop
    hydrated_predicates =
      Enum.map(loop_def.predicates, fn pred_ref ->
        hydrate_predicate(pred_ref, module)
      end)

    # Create a Loop struct with the hydrated predicates
    Loop.new(
      loop_def.name,
      loop_def.description || "",
      hydrated_predicates
    )
  end

  # Hydrates a predicate definition or reference into a fully executable Predicate struct
  defp hydrate_predicate(pred_ref, module) do
    case pred_ref do
      # It's already a proper Predicate struct with an implementation
      %{name: _, description: _, fn_impl: fn_impl} when is_function(fn_impl, 1) ->
        pred_ref

      # It's a reference to a predicate by name
      %{name: name, inline: false} ->
        apply(module, :get_predicate, [name])

      # It's an inline predicate definition with a body to evaluate
      %{name: name, description: description, body: body} ->
        fn_impl = Riffle.Predicate.create(body)
        Riffle.Predicate.new(name, description || "", fn_impl)

      # Unknown format
      _ ->
        raise "Unrecognized predicate reference format: #{inspect(pred_ref)}"
    end
  end

  @doc """
  Validates that a pipeline definitions map includes a :main pipeline.

  This is a convention check to ensure that pipeline definition modules
  follow the standard practice of providing a :main entry point pipeline.

  ## Parameters
    * `pipeline_defs` - Pipeline definitions map

  ## Returns
    * `:ok` if a :main pipeline is found
    * `{:error, :missing_main_pipeline}` if no :main pipeline is found
  """
  @spec validate_has_main_pipeline(map()) :: :ok | {:error, :missing_main_pipeline}
  def validate_has_main_pipeline(pipeline_defs) do
    # Check if the loaded pipeline definitions contain a :main pipeline
    pipelines = pipeline_defs[:pipelines] || []
    has_main = Enum.any?(pipelines, fn pipeline -> pipeline.name == :main end)

    if has_main do
      :ok
    else
      {:error, :missing_main_pipeline}
    end
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
end
