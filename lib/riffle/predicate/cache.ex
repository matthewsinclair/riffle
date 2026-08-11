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
  @type cache_key :: {atom(), Item.t()}
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

  `Riffle.Application` starts the cache under the supervision tree, so an
  application that depends on `:riffle` has one already. It is a named
  singleton, and a second `start_link/1` says so rather than quietly handing
  back a second cache:

      iex> {:error, {:already_started, pid}} = Riffle.Predicate.Cache.start_link()
      iex> is_pid(pid)
      true

  The example that used to sit here asserted `{:ok, _pid}` twice over, which
  had never run: nothing declared a doctest for this module, so a claim that
  was false the moment the supervisor booted went unchecked.
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

      iex> item = Riffle.Predicate.Item.create(%{"status" => "active"})
      iex> Riffle.Predicate.Cache.get(:doc_never_cached, item)
      {:error, :not_found}
  """
  @spec get(atom(), Item.t()) :: {:ok, any()} | {:error, :not_found | :disabled}
  def get(predicate_id, %Item{} = item) do
    case GenServer.call(__MODULE__, :enabled?) do
      true -> lookup(generate_key(predicate_id, item))
      false -> {:error, :disabled}
    end
  end

  defp lookup(key) do
    case :ets.lookup(@table_name, key) do
      [{^key, {value, expiry}}] -> take_if_fresh(key, value, expiry)
      [] -> miss()
    end
  end

  # An expired entry is evicted on the read that found it, so a stale value is
  # never returned and never lingers.
  defp take_if_fresh(key, value, expiry) do
    case System.os_time(:second) < expiry do
      true ->
        GenServer.cast(__MODULE__, {:record_hit})
        {:ok, value}

      false ->
        GenServer.cast(__MODULE__, {:remove, key})
        miss()
    end
  end

  defp miss do
    GenServer.cast(__MODULE__, {:record_miss})
    {:error, :not_found}
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

      iex> item = Riffle.Predicate.Item.create(%{"status" => "active"})
      iex> tagged = Riffle.Predicate.Item.add_tag(item, :doc_put_example)
      iex> Riffle.Predicate.Cache.put(:doc_put_example, item, {true, tagged})
      :ok
      iex> Riffle.Predicate.Cache.get(:doc_put_example, item)
      {:ok, {true, tagged}}
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
  Resets hit/miss statistics to zero. Cache contents are untouched.

  ## Returns

  * `:ok` - Always returns :ok
  """
  @spec reset_stats() :: :ok
  def reset_stats do
    GenServer.call(__MODULE__, :reset_stats)
  end

  @doc """
  Returns the current cache configuration.

  ## Returns

  * `config` - Map with `:enabled`, `:max_size`, and `:ttl`
  """
  @spec config() :: config()
  def config do
    GenServer.call(__MODULE__, :config)
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
  def handle_call(:reset_stats, _from, state) do
    {:reply, :ok, %{state | stats: %{hits: 0, misses: 0, size: 0}}}
  end

  @impl true
  def handle_call(:config, _from, state) do
    {:reply, state.config, state}
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
    # The key is the exact item, not a hash of a sample of it. An earlier
    # optimisation keyed on the first three field values plus a field count,
    # which made distinct rows share keys -- and a shared key returns another
    # row's cached result as a silent wrong answer. ETS compares full terms;
    # exactness is the point of a cache key.
    {predicate_id, item}
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
