defmodule Riffle.Predicate do
  @moduledoc """
  Core module for defining and evaluating predicates.

  A predicate is a function that takes an item and returns a result indicating
  whether the predicate matches and what tags or metadata to attach.

  ## Examples

      iex> alias Riffle.{Predicate, Predicate.Item}
      iex> predicate = Predicate.new(:active, "Active users", fn item -> item.fields["status"] == "active" end)
      iex> item = Item.new(["status"], ["active"])
      iex> {matched, updated_item} = Predicate.evaluate(predicate, item)
      iex> matched
      true
      iex> updated_item.tags
      [:active]
  """

  alias Riffle.Predicate.Item
  alias Riffle.Predicate.Cache

  @type predicate_function :: (Item.t() -> predicate_result())
  @type predicate_result :: boolean() | [atom()] | {boolean(), map()} | {[atom()], map()}
  @type predicate_definition :: %{
          name: atom(),
          description: String.t(),
          function: predicate_function()
        }

  @doc """
  Creates a new predicate definition.

  ## Parameters
    * `name` - Name of the predicate (atom)
    * `description` - Human-readable description
    * `function` - Function that evaluates the predicate

  ## Returns
    * A predicate definition map

  ## Examples

      iex> alias Riffle.{Predicate, Predicate.Item}
      iex> predicate = Predicate.new(:active, "Active users", fn item -> item.fields["status"] == "active" end)
      iex> predicate.name == :active and predicate.description == "Active users" and is_function(predicate.function, 1)
      true
  """
  @spec new(atom(), String.t(), predicate_function()) :: predicate_definition()
  def new(name, description, function)
      when is_atom(name) and is_binary(description) and is_function(function, 1) do
    %{name: name, description: description, function: function}
  end

  @doc """
  Evaluates a predicate on an item.

  This version first checks the cache for a previous evaluation result. If found,
  it returns the cached result. Otherwise, it evaluates the predicate directly
  and caches the result.

  ## Parameters
    * `predicate` - The predicate definition
    * `item` - The item to evaluate

  ## Returns
    * Tuple of {matched, updated_item}

  ## Examples

      iex> alias Riffle.{Predicate, Predicate.Item}
      iex> predicate = Predicate.new(:active, "Active users", fn item -> item.fields["status"] == "active" end)
      iex> item = Item.new(["status"], ["active"])
      iex> {matched, updated_item} = Predicate.evaluate(predicate, item)
      iex> matched
      true
      iex> updated_item.tags
      [:active]
  """
  @spec evaluate(predicate_definition(), Item.t()) :: {boolean(), Item.t()}
  def evaluate(%{name: name} = predicate, %Item{} = item) do
    # Check if there's a cached result first
    case Cache.get(name, item) do
      {:ok, result} ->
        # Cache hit - use cached result
        result

      {:error, _reason} ->
        # Cache miss or disabled - evaluate directly
        result = evaluate_direct(predicate, item)

        # Cache the result for future use (unless cache is disabled)
        # This will be a no-op if caching is disabled
        Cache.put(name, item, result)

        result
    end
  end

  @doc false
  # Function to directly evaluate a predicate without caching
  @spec evaluate_direct(predicate_definition(), Item.t()) :: {boolean(), Item.t()}
  # Handle standard predicate definitions with function key
  def evaluate_direct(%{name: name, function: function}, %Item{} = item) do
    case function.(item) do
      false ->
        {false, item}

      true ->
        {true, Item.add_tag(item, name)}

      tags when is_list(tags) ->
        if Enum.all?(tags, &is_atom/1) do
          {true, Item.add_tags(item, tags)}
        else
          raise ArgumentError, "Tag list must contain only atoms, got: #{inspect(tags)}"
        end

      {true, metadata} when is_map(metadata) ->
        {true, item |> Item.add_tag(name) |> Item.add_metadata(metadata)}

      {tags, metadata} when is_list(tags) and is_map(metadata) ->
        if Enum.all?(tags, &is_atom/1) do
          {true, item |> Item.add_tags(tags) |> Item.add_metadata(metadata)}
        else
          raise ArgumentError, "Tag list must contain only atoms, got: #{inspect(tags)}"
        end

      other ->
        raise ArgumentError,
              "Invalid predicate result: #{inspect(other)}. " <>
                "Must be boolean, list of atoms, or tuple {boolean|[atom()], map()}"
    end
  end

  # Handle predicates with body but no function yet - this is for cases when we need to 
  # evaluate predicates defined in macros that haven't been fully processed
  def evaluate_direct(%{name: _name, body: body} = predicate, %Item{} = item) do
    # Create the function implementation from the body
    function = create(body)
    # Update the predicate with the function
    predicate_with_function = Map.put(predicate, :function, function)
    # Evaluate with the function
    evaluate_direct(predicate_with_function, item)
  end

  # Handle predicate references that only have a name and inline: false
  def evaluate_direct(%{name: name, inline: false}, %Item{} = _item) do
    # This is just a reference to a predicate - we need to get the actual predicate definition
    # Since this may be called in the context of a module that has the get_predicate function,
    # we'll raise an error here with clear guidance about how to fix
    raise "Cannot evaluate predicate reference #{inspect(name)} directly. " <>
            "Make sure all predicate references are resolved to actual predicate definitions " <>
            "before calling evaluate or filter."
  end

  @doc """
  Creates a predicate from an anonymous function.

  ## Parameters
    * `name` - Name of the predicate (atom)
    * `description` - Human-readable description
    * `function` - Anonymous function that takes an item and returns a predicate result

  ## Returns
    * A predicate definition

  ## Examples

      iex> alias Riffle.{Predicate, Predicate.Item}
      iex> predicate = Predicate.from_function(:active, "Active users", fn item -> item.fields["status"] == "active" end)
      iex> predicate.name == :active and predicate.description == "Active users" and is_function(predicate.function, 1)
      true
  """
  @spec from_function(atom(), String.t(), (Item.t() -> predicate_result())) ::
          predicate_definition()
  def from_function(name, description, function) do
    new(name, description, function)
  end

  @doc """
  Creates a predicate that calls an existing function.

  ## Parameters
    * `name` - Name of the predicate (atom)
    * `description` - Human-readable description
    * `function` - Function reference that takes an item and returns a predicate result

  ## Returns
    * A predicate definition

  ## Examples

      iex> alias Riffle.{Predicate, Predicate.Item}
      iex> defmodule Riffle.Predicate.DocTest.TestModule do
      ...>   def is_active(item), do: item.fields["status"] == "active"
      ...> end
      iex> predicate = Predicate.from_call(:active, "Active users", &Riffle.Predicate.DocTest.TestModule.is_active/1)
      iex> predicate.name == :active and predicate.description == "Active users" and is_function(predicate.function, 1)
      true
  """
  @spec from_call(atom(), String.t(), function()) :: predicate_definition()
  def from_call(name, description, function) when is_function(function, 1) do
    new(name, description, function)
  end

  @doc """
  Creates a compound predicate that checks for the presence of tags from other predicates.

  ## Parameters
    * `name` - Name of the predicate (atom)
    * `description` - Human-readable description
    * `tags` - List of tags to check for (all must be present)

  ## Returns
    * A predicate definition

  ## Examples

      iex> alias Riffle.{Predicate, Predicate.Item}
      iex> item = %Item{tags: [:premium, :active, :other]}
      iex> predicate = Predicate.from_check(:premium_active, "Premium active users", [:premium, :active])
      iex> {matched, _} = Predicate.evaluate(predicate, item)
      iex> matched
      true
  """
  @spec from_check(atom(), String.t(), [atom()]) :: predicate_definition()
  def from_check(name, description, tags)
      when is_atom(name) and is_binary(description) and is_list(tags) do
    new(name, description, fn item ->
      Enum.all?(tags, &Item.has_tag?(item, &1))
    end)
  end

  @doc """
  Creates a predicate from a DSL expression.

  ## Parameters
    * `name` - Name of the predicate (atom)
    * `description` - Human-readable description
    * `expression` - String containing a DSL expression

  ## Returns
    * `{:ok, predicate}` or `{:error, reason}`

  ## Examples

      iex> alias Riffle.{Predicate, Predicate.Item}
      iex> {:ok, predicate} = Predicate.from_expression(:active, "Active users", "fields[\\"status\\"] == \\"active\\"")
      iex> item = Item.new(["status"], ["active"])
      iex> {matched, updated_item} = Predicate.evaluate(predicate, item)
      iex> matched
      true
      iex> updated_item.tags
      [:active]
  """
  @spec from_expression(atom(), String.t(), String.t()) ::
          {:ok, predicate_definition()} | {:error, term()}
  def from_expression(name, description, expression)
      when is_atom(name) and is_binary(description) and is_binary(expression) do
    alias Riffle.Predicate.Dsl.Evaluator

    case Evaluator.parse(expression) do
      {:ok, function} -> {:ok, new(name, description, function)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Creates a predicate function from a function.

  This is a simplified interface used by the DSL modules.

  ## Parameters
    * `function` - The function that implements the predicate
    
  ## Returns
    * A predicate function
    
  ## Examples

      iex> alias Riffle.{Predicate, Predicate.Item}
      iex> pred_fn = Predicate.create(fn item -> item.fields["status"] == "active" end)
      iex> is_function(pred_fn, 1)
      true
      iex> item = Item.new(["status"], ["active"])
      iex> pred_fn.(item)
      true
  """
  @spec create(function() | any()) :: function()
  def create(function) when is_function(function, 1) do
    function
  end

  def create({:expr, expression}) do
    # Handle expression syntax with @field_name
    alias Riffle.Predicate.Dsl.Evaluator

    # Handle both string expressions and AST expressions
    case expression do
      expr when is_binary(expr) ->
        # String-based expression
        case Evaluator.parse(expr) do
          {:ok, function} -> function
          {:error, error} -> raise ArgumentError, "Error parsing expression: #{inspect(error)}"
        end

      # Handle keyword lists (which is what we expect from properly processed expr macros)
      expr when is_list(expr) ->
        expr_str = if Keyword.keyword?(expr), do: Macro.to_string(expr), else: inspect(expr)

        case Evaluator.parse(expr_str) do
          {:ok, function} ->
            function

          {:error, error} ->
            raise ArgumentError,
                  "Error parsing expression: #{inspect(expr_str)} - #{inspect(error)}"
        end

      # For other AST expressions (maps or tuples from Macro.escape)
      expr ->
        expr_str = Macro.to_string(expr)

        case Evaluator.parse(expr_str) do
          {:ok, function} ->
            function

          {:error, error} ->
            raise ArgumentError,
                  "Error parsing expression: #{inspect(expr_str)} - #{inspect(error)}"
        end
    end
  end

  # Raw expr AST as parsed from .pred files: {:expr, meta, [expression]}.
  def create({:expr, meta, [expression]}) when is_list(meta) do
    create({:expr, expression})
  end

  def create({:__block__, _, _statements} = ast_body) do
    # A body that fails to evaluate is a defect in the predicate definition;
    # the raise propagates from evaluation. It must never quietly become an
    # always-false predicate that filters every item with no signal.
    fn _item ->
      {result, _bindings} = Code.eval_quoted(ast_body)
      result
    end
  end

  def create(ast_body) do
    {function, _bindings} = Code.eval_quoted(ast_body)

    if is_function(function, 1) do
      function
    else
      fn _item -> function end
    end
  rescue
    e ->
      reraise ArgumentError,
              [
                message:
                  "predicate body failed to evaluate: #{Exception.message(e)} " <>
                    "-- body AST: #{inspect(ast_body)}"
              ],
              __STACKTRACE__
  end

  @doc """
  Enables or disables caching for predicate evaluations.

  ## Parameters
    * `enabled` - Boolean indicating whether caching should be enabled

  ## Returns
    * `{:ok, config}` - Updated configuration
    * `{:error, reason}` - Error if configuration couldn't be updated

  ## Examples

      iex> {:ok, config} = Riffle.Predicate.with_caching(false)
      iex> config.enabled
      false
  """
  @spec with_caching(boolean) :: {:ok, Cache.config()} | {:error, term()}
  def with_caching(enabled) when is_boolean(enabled) do
    Cache.configure(enabled: enabled)
  end

  @doc """
  Configures the predicate evaluation cache.

  ## Parameters
    * `opts` - Keyword list of configuration options

  ## Options
    * `:max_size` - Maximum number of entries in the cache
    * `:ttl` - Time to live for cache entries in seconds
    * `:enabled` - Whether caching is enabled

  ## Returns
    * `{:ok, config}` - Updated configuration
    * `{:error, reason}` - Error if configuration couldn't be updated

  ## Examples

      iex> {:ok, config} = Riffle.Predicate.configure_cache(max_size: 5000, ttl: 1800)
      iex> config.max_size
      5000
      iex> config.ttl
      1800
  """
  @spec configure_cache(keyword()) :: {:ok, Cache.config()} | {:error, term()}
  def configure_cache(opts) when is_list(opts) do
    Cache.configure(opts)
  end

  @doc """
  Clears the predicate evaluation cache.

  ## Returns
    * `:ok` - Cache was successfully cleared

  ## Examples

      iex> Riffle.Predicate.clear_cache()
      :ok
  """
  @spec clear_cache() :: :ok
  def clear_cache do
    Cache.clear()
  end

  @doc """
  Gets statistics about the predicate evaluation cache.

  ## Returns
    * `stats` - Map with cache statistics including hits, misses, and size

  ## Examples

      iex> stats = Riffle.Predicate.cache_stats()
      iex> Enum.sort(Map.keys(stats))
      [:hits, :misses, :size]
  """
  @spec cache_stats() :: Cache.cache_stats()
  def cache_stats do
    Cache.stats()
  end

  @doc """
  The configured default pipeline module, or `nil` when none is configured.

  When a pipeline or loop lacks its own module context, predicate-reference
  resolution falls back to this module (`config :riffle, :default_pipeline`).
  The engine itself never names a concrete pipeline module.
  """
  @spec default_pipeline() :: module() | nil
  def default_pipeline do
    Application.get_env(:riffle, :default_pipeline)
  end
end

defmodule Riffle.Predicate.UnresolvedPredicateError do
  @moduledoc """
  Raised when a predicate reference cannot be resolved to a definition --
  neither through the referencing loop's module context nor through the
  configured default pipeline (`config :riffle, :default_pipeline`).
  """
  defexception [:message]
end
