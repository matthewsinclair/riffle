defmodule Riffle.Predicate.Cache do
  @moduledoc """
  Caching system for Predicate evaluations to improve performance.

  This module provides ETS-based caching of predicate evaluation results to avoid
  redundant evaluations of the same predicate against the same item.

  ## Features

  * In-memory caching using ETS tables for fast access
  * GenServer-based cache management (lifecycle, stats)
  * Configurable cache size and TTL (Time To Live)
  * Support for enabling/disabling caching globally
  * Cache statistics for monitoring performance
  """

  use GenServer
  alias Riffle.Predicate.Item

  # Cache table name
  @table_name :predicate_cache

  # Default configuration
  @default_config %{
    enabled: true,
    max_size: 10_000,
    # seconds
    ttl: 3600
  }

  # Types
  @type cache_key :: {atom(), String.t()}
  @type cache_value :: {any(), non_neg_integer()}
  @type cache_stats :: %{
          hits: non_neg_integer(),
          misses: non_neg_integer(),
          size: non_neg_integer()
        }
  @type config_option ::
          {:enabled, boolean()}
          | {:max_size, pos_integer()}
          | {:ttl, non_neg_integer()}
  @type config :: %{
          enabled: boolean(),
          max_size: pos_integer(),
          ttl: non_neg_integer()
        }

  #
  # Client API
  #

  @doc """
  Starts the cache GenServer.

  ## Options

  * `:enabled` - Whether the cache is enabled (default: true)
  * `:max_size` - Maximum number of entries in the cache (default: 10,000)
  * `:ttl` - Time to live for cache entries in seconds (default: 3600)

  ## Examples

      iex> {:ok, _pid} = Riffle.Predicate.Cache.start_link()
      iex> {:ok, _pid} = Riffle.Predicate.Cache.start_link(enabled: false)
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    config = Enum.into(opts, @default_config)
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  @doc """
  Gets a value from the cache.

  ## Parameters

  * `predicate_id` - The identifier of the predicate
  * `item` - The item being evaluated

  ## Returns

  * `{:ok, value}` - If the value is found in the cache
  * `{:error, :not_found}` - If the value is not found
  * `{:error, :disabled}` - If caching is disabled

  ## Examples

      iex> Riffle.Predicate.Cache.get(:active, item)
      {:error, :not_found}
  """
  @spec get(atom(), Item.t()) :: {:ok, any()} | {:error, :not_found | :disabled}
  def get(predicate_id, %Item{} = item) do
    case GenServer.call(__MODULE__, :enabled?) do
      true ->
        key = generate_key(predicate_id, item)

        case :ets.lookup(@table_name, key) do
          [{^key, {value, expiry}}] ->
            current_time = System.os_time(:second)

            if current_time < expiry do
              GenServer.cast(__MODULE__, {:record_hit})
              {:ok, value}
            else
              GenServer.cast(__MODULE__, {:remove, key})
              GenServer.cast(__MODULE__, {:record_miss})
              {:error, :not_found}
            end

          [] ->
            GenServer.cast(__MODULE__, {:record_miss})
            {:error, :not_found}
        end

      false ->
        {:error, :disabled}
    end
  end

  @doc """
  Puts a value into the cache.

  ## Parameters

  * `predicate_id` - The identifier of the predicate
  * `item` - The item being evaluated
  * `value` - The value to cache

  ## Returns

  * `:ok` - If the value was successfully cached
  * `{:error, :disabled}` - If caching is disabled

  ## Examples

      iex> Riffle.Predicate.Cache.put(:active, item, {true, updated_item})
      :ok
  """
  @spec put(atom(), Item.t(), any()) :: :ok | {:error, :disabled}
  def put(predicate_id, %Item{} = item, value) do
    case GenServer.call(__MODULE__, :enabled?) do
      true ->
        key = generate_key(predicate_id, item)
        GenServer.cast(__MODULE__, {:put, key, value})
        :ok

      false ->
        {:error, :disabled}
    end
  end

  @doc """
  Clears the entire cache.

  ## Returns

  * `:ok` - Always returns :ok

  ## Examples

      iex> Riffle.Predicate.Cache.clear()
      :ok
  """
  @spec clear() :: :ok
  def clear do
    GenServer.cast(__MODULE__, :clear)
  end

  @doc """
  Retrieves cache statistics.

  ## Returns

  * `stats` - A map with cache statistics

  ## Examples

      iex> stats = Riffle.Predicate.Cache.stats()
      iex> is_map(stats) and is_integer(stats.hits) and is_integer(stats.misses)
      true
  """
  @spec stats() :: cache_stats()
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @doc """
  Updates the cache configuration.

  ## Parameters

  * `opts` - Keyword list of configuration options

  ## Options

  * `:enabled` - Whether the cache is enabled
  * `:max_size` - Maximum number of entries in the cache
  * `:ttl` - Time to live for cache entries in seconds

  ## Returns

  * `{:ok, config}` - Updated configuration
  * `{:error, reason}` - Error with reason

  ## Examples

      iex> {:ok, config} = Riffle.Predicate.Cache.configure(enabled: false)
      iex> config.enabled
      false
  """
  @spec configure(keyword()) :: {:ok, config()} | {:error, term()}
  def configure(opts) do
    GenServer.call(__MODULE__, {:configure, opts})
  end

  #
  # Server Callbacks
  #

  @impl true
  def init(config) do
    # Create the ETS table for the cache
    table_opts = [
      :set,
      :protected,
      :named_table,
      {:read_concurrency, true}
    ]

    :ets.new(@table_name, table_opts)

    state = %{
      config: config,
      stats: %{
        hits: 0,
        misses: 0,
        size: 0
      }
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:enabled?, _from, state) do
    {:reply, state.config.enabled, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    # Update the size stat with current table size
    size = :ets.info(@table_name, :size)
    stats = %{state.stats | size: size}

    {:reply, stats, %{state | stats: stats}}
  end

  @impl true
  def handle_call({:configure, opts}, _from, state) do
    case validate_config(opts) do
      {:ok, valid_opts} ->
        new_config = Map.merge(state.config, valid_opts)
        {:reply, {:ok, new_config}, %{state | config: new_config}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_cast({:record_hit}, state) do
    new_stats = %{state.stats | hits: state.stats.hits + 1}
    {:noreply, %{state | stats: new_stats}}
  end

  @impl true
  def handle_cast({:record_miss}, state) do
    new_stats = %{state.stats | misses: state.stats.misses + 1}
    {:noreply, %{state | stats: new_stats}}
  end

  @impl true
  def handle_cast({:put, key, value}, state) do
    # Check if we need to perform cache eviction
    current_size = :ets.info(@table_name, :size)

    if current_size >= state.config.max_size do
      # Simple random eviction for now
      # In a more advanced implementation, we could use LRU policy
      :ets.delete(@table_name, random_key())
    end

    # Calculate expiry time
    expiry = System.os_time(:second) + state.config.ttl
    :ets.insert(@table_name, {key, {value, expiry}})

    {:noreply, state}
  end

  @impl true
  def handle_cast({:remove, key}, state) do
    :ets.delete(@table_name, key)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:clear, state) do
    :ets.delete_all_objects(@table_name)
    new_stats = %{state.stats | size: 0}
    {:noreply, %{state | stats: new_stats}}
  end

  #
  # Private Functions
  #

  @spec generate_key(atom(), Item.t()) :: cache_key()
  defp generate_key(predicate_id, %Item{} = item) do
    # Use a more efficient hash generation that is optimized for large datasets
    # but doesn't make assumptions about specific field names

    # For complex items, hashing the entire fields structure can be expensive
    # We'll create a more efficient hash using a subset of the item's properties

    # Instead of scanning the whole item structure, we'll combine:
    # 1. The hash of the first 3 values (which typically are the most important discriminating values)
    # 2. The number of fields (quick metadata that helps distinguish items)
    # 3. The hash of signal tags (most important tag type for predicates)

    # Get signal tags (they're most important for predicate evaluation)
    signal_tags =
      Enum.filter(item.tags, fn tag ->
        tag_str = Atom.to_string(tag)
        String.starts_with?(tag_str, "signal_")
      end)

    # Take first few values and tag info to create an efficient hash
    # This provides good distinction without the full expense of hashing everything
    sample_values = Enum.take(Map.values(item.fields), 3)
    field_count = map_size(item.fields)

    # Create a focused hash combining these elements
    item_hash = :erlang.phash2({sample_values, field_count, signal_tags})

    {predicate_id, to_string(item_hash)}
  end

  @spec random_key() :: cache_key() | nil
  defp random_key do
    # Pick a random key for eviction
    # This is a simple implementation - could be enhanced with LRU policy
    case :ets.tab2list(@table_name) do
      [] ->
        nil

      entries ->
        {key, _} = Enum.random(entries)
        key
    end
  end

  @spec validate_config(keyword()) :: {:ok, map()} | {:error, term()}
  defp validate_config(opts) do
    with {:ok, enabled} <- validate_enabled(opts[:enabled]),
         {:ok, max_size} <- validate_max_size(opts[:max_size]),
         {:ok, ttl} <- validate_ttl(opts[:ttl]) do
      valid_opts = %{}

      valid_opts =
        if opts[:enabled] != nil, do: Map.put(valid_opts, :enabled, enabled), else: valid_opts

      valid_opts =
        if opts[:max_size] != nil, do: Map.put(valid_opts, :max_size, max_size), else: valid_opts

      valid_opts = if opts[:ttl] != nil, do: Map.put(valid_opts, :ttl, ttl), else: valid_opts

      {:ok, valid_opts}
    end
  end

  defp validate_enabled(nil), do: {:ok, nil}
  defp validate_enabled(enabled) when is_boolean(enabled), do: {:ok, enabled}
  defp validate_enabled(invalid), do: {:error, {:invalid_enabled, invalid}}

  defp validate_max_size(nil), do: {:ok, nil}
  defp validate_max_size(max_size) when is_integer(max_size) and max_size > 0, do: {:ok, max_size}
  defp validate_max_size(invalid), do: {:error, {:invalid_max_size, invalid}}

  defp validate_ttl(nil), do: {:ok, nil}
  defp validate_ttl(ttl) when is_integer(ttl) and ttl >= 0, do: {:ok, ttl}
  defp validate_ttl(invalid), do: {:error, {:invalid_ttl, invalid}}
end
