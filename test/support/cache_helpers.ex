defmodule Riffle.CacheHelpers do
  @moduledoc """
  The one home for cache-suite preconditions and evaluation-counting spy
  predicates (test-highlander): each cache suite's setup reads as one call.
  """

  alias Riffle.Predicate
  alias Riffle.Predicate.Cache

  @doc """
  Resets the global cache to known settings (merged over enabled/10k/1h
  defaults), empties it, and zeroes its stats.
  """
  @spec reset_cache(keyword()) :: :ok
  def reset_cache(opts \\ []) do
    config = Keyword.merge([enabled: true, max_size: 10_000, ttl: 3600], opts)
    {:ok, _config} = Cache.configure(config)
    :ok = Cache.clear()
    :ok = Cache.reset_stats()
  end

  @doc """
  A predicate definition whose function bumps `:counters` slot `index` on
  every evaluation before applying `check` -- the cache suites' spy for
  proving when evaluation did and did not happen.
  """
  @spec spy_predicate(atom(), :counters.counters_ref(), pos_integer(), (term() -> boolean())) ::
          Predicate.predicate_definition()
  def spy_predicate(name, counters, index, check) do
    Predicate.new(name, "spy: #{name}", fn item ->
      :counters.add(counters, index, 1)
      check.(item)
    end)
  end
end
