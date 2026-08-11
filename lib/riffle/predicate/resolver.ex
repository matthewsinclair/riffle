defmodule Riffle.Predicate.Resolver do
  @moduledoc """
  The single resolution and hydration path for predicate, loop, and pipeline
  references.

  A *source* is where definitions live:

    * a module exporting `c:Riffle.Predicate.PipelineConfig.get_predicate/1`
      (and `c:Riffle.Predicate.PipelineConfig.get_loop/1` /
      `c:Riffle.Predicate.PipelineConfig.get_pipeline/1` as needed) -- DSL
      macro modules and pipeline-config modules
    * a definitions map `%{predicates: %{}, loops: %{}, pipelines: %{}}` --
      registry state and loader-built instances
    * `nil` -- resolution falls back to the configured default pipeline
      (`config :riffle, :default_pipeline`), read lazily at lookup time, so
      refs that need no lookup (inline bodies, runnable definitions) resolve
      without touching config

  Resolution output is always runnable: references are chased recursively,
  inline bodies are materialised into functions exactly once via
  `Riffle.Predicate.create/1`, and structs are re-walked so half-resolved
  innards cannot leak through. There is no benign catch-all: unknown shapes,
  missing names, absent sources, and reference cycles are all tagged errors,
  and the bang variants raise `Riffle.Predicate.UnresolvedPredicateError`.
  """

  alias Riffle.Predicate.Loop
  alias Riffle.Predicate.Pipeline

  @type kind :: :predicate | :loop | :pipeline
  @type defs_map :: %{predicates: map(), loops: map(), pipelines: map()}
  @type source :: module() | defs_map() | nil
  @type looked_in :: module() | :definitions
  @type reason ::
          {:unresolved, kind(), atom(), looked_in()}
          | {:invalid_ref, kind(), term()}
          | {:no_source, atom()}
          | {:cycle, kind(), [atom()]}

  @doc """
  Resolves a predicate ref to a runnable definition (`%{name, description,
  function}`) against the given source.

  Accepts a runnable definition (passed through), a reference
  (`%{name: name, inline: false}`, chased through the source), or an inline
  definition (`%{name: name, body: body}`, hydrated once).
  """
  @spec resolve_predicate(source(), term()) ::
          {:ok, Riffle.Predicate.predicate_definition()} | {:error, reason()}
  def resolve_predicate(source, ref), do: do_resolve_predicate(source, ref, [])

  @doc """
  Resolves a loop ref to a `Riffle.Predicate.Loop` struct whose predicates are
  all runnable. Structs are re-walked; references are chased; inline loop maps
  are hydrated.
  """
  @spec resolve_loop(source(), term()) :: {:ok, Loop.t()} | {:error, reason()}
  def resolve_loop(source, ref), do: do_resolve_loop(source, ref, [])

  @doc """
  Resolves a pipeline ref to a `Riffle.Predicate.Pipeline` struct, recursively
  resolving its loops and their predicates.
  """
  @spec resolve_pipeline(source(), term()) :: {:ok, Pipeline.t()} | {:error, reason()}
  def resolve_pipeline(source, ref), do: do_resolve_pipeline(source, ref, [])

  @doc """
  Same as `resolve_predicate/2` but raises `Riffle.Predicate.UnresolvedPredicateError`.
  """
  @spec resolve_predicate!(source(), term()) :: Riffle.Predicate.predicate_definition()
  def resolve_predicate!(source, ref), do: bang(resolve_predicate(source, ref))

  @doc """
  Same as `resolve_loop/2` but raises `Riffle.Predicate.UnresolvedPredicateError`.
  """
  @spec resolve_loop!(source(), term()) :: Loop.t()
  def resolve_loop!(source, ref), do: bang(resolve_loop(source, ref))

  @doc """
  Same as `resolve_pipeline/2` but raises `Riffle.Predicate.UnresolvedPredicateError`.
  """
  @spec resolve_pipeline!(source(), term()) :: Pipeline.t()
  def resolve_pipeline!(source, ref), do: bang(resolve_pipeline(source, ref))

  # Predicate resolution. Runnable-definition passthrough first so re-walks
  # are idempotent; a :function key holding anything but an arity-1 function
  # is invalid, never re-hydrated.

  defp do_resolve_predicate(_source, %{function: function} = definition, _path)
       when is_function(function, 1) do
    {:ok, definition}
  end

  defp do_resolve_predicate(_source, %{function: _} = ref, _path) do
    {:error, {:invalid_ref, :predicate, ref}}
  end

  defp do_resolve_predicate(source, %{name: name, inline: false}, path) do
    chase(source, :predicate, name, path, &do_resolve_predicate/3)
  end

  defp do_resolve_predicate(_source, %{name: name, body: body} = ref, _path) do
    definition =
      Riffle.Predicate.new(
        name,
        Map.get(ref, :description) || "",
        Riffle.Predicate.create(body)
      )

    {:ok, definition}
  end

  defp do_resolve_predicate(_source, ref, _path) do
    {:error, {:invalid_ref, :predicate, ref}}
  end

  # Loop resolution.

  defp do_resolve_loop(source, %Loop{predicates: predicates} = loop, _path) do
    with {:ok, resolved} <- resolve_all(predicates, &do_resolve_predicate(source, &1, [])) do
      {:ok, %Loop{loop | predicates: resolved}}
    end
  end

  defp do_resolve_loop(source, %{name: name, inline: false}, path) do
    chase(source, :loop, name, path, &do_resolve_loop/3)
  end

  defp do_resolve_loop(source, %{name: name, predicates: predicates} = ref, _path) do
    with {:ok, resolved} <- resolve_all(predicates, &do_resolve_predicate(source, &1, [])) do
      {:ok, Loop.new(name, Map.get(ref, :description) || "", resolved)}
    end
  end

  defp do_resolve_loop(_source, ref, _path) do
    {:error, {:invalid_ref, :loop, ref}}
  end

  # Pipeline resolution.

  defp do_resolve_pipeline(source, %Pipeline{loops: loops} = pipeline, _path) do
    with {:ok, resolved} <- resolve_all(loops, &do_resolve_loop(source, &1, [])) do
      {:ok, %Pipeline{pipeline | loops: resolved}}
    end
  end

  defp do_resolve_pipeline(source, %{name: name, inline: false}, path) do
    chase(source, :pipeline, name, path, &do_resolve_pipeline/3)
  end

  defp do_resolve_pipeline(source, %{name: name, loops: loops} = ref, _path) do
    with {:ok, resolved} <- resolve_all(loops, &do_resolve_loop(source, &1, [])) do
      {:ok, Pipeline.new(name, Map.get(ref, :description) || "", resolved)}
    end
  end

  defp do_resolve_pipeline(_source, ref, _path) do
    {:error, {:invalid_ref, :pipeline, ref}}
  end

  # One chase for all three kinds: cycle check, lookup, recurse into whatever
  # the source returned (definition, another ref, or a struct).

  defp chase(source, kind, name, path, continue) do
    if name in path do
      {:error, {:cycle, kind, Enum.reverse([name | path])}}
    else
      with {:ok, definition} <- lookup(source, kind, name) do
        continue.(source, definition, [name | path])
      end
    end
  end

  defp resolve_all(refs, resolve_one) do
    refs
    |> Enum.reduce_while({:ok, []}, fn ref, {:ok, acc} ->
      case resolve_one.(ref) do
        {:ok, resolved} -> {:cont, {:ok, [resolved | acc]}}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
    |> finish()
  end

  defp finish({:ok, acc}), do: {:ok, Enum.reverse(acc)}
  defp finish({:error, _reason} = error), do: error

  # The only functions that know what kind of source they hold. `nil` must
  # precede the module clause: nil is an atom.

  defp lookup(nil, kind, name) do
    case Riffle.Predicate.default_pipeline() do
      nil -> {:error, {:no_source, name}}
      module -> lookup(module, kind, name)
    end
  end

  defp lookup(%{predicates: _, loops: _, pipelines: _} = defs, kind, name) do
    case Map.fetch(collection(defs, kind), name) do
      {:ok, definition} -> {:ok, definition}
      :error -> {:error, {:unresolved, kind, name, :definitions}}
    end
  end

  defp lookup(module, kind, name) when is_atom(module) do
    getter = getter(kind)

    # Boolean capability probes, not shape dispatch: a module that is absent,
    # not compiled, or lacking the getter is the same failure to the caller.
    cond do
      not Code.ensure_loaded?(module) -> {:error, {:unresolved, kind, name, module}}
      not function_exported?(module, getter, 1) -> {:error, {:unresolved, kind, name, module}}
      true -> found(apply(module, getter, [name]), kind, name, module)
    end
  end

  defp found(nil, kind, name, module), do: {:error, {:unresolved, kind, name, module}}
  defp found(definition, _kind, _name, _module), do: {:ok, definition}

  defp getter(:predicate), do: :get_predicate
  defp getter(:loop), do: :get_loop
  defp getter(:pipeline), do: :get_pipeline

  defp collection(defs, :predicate), do: defs.predicates
  defp collection(defs, :loop), do: defs.loops
  defp collection(defs, :pipeline), do: defs.pipelines

  # Bang plumbing: error text is built here and nowhere else.

  defp bang({:ok, resolved}), do: resolved

  defp bang({:error, reason}) do
    raise Riffle.Predicate.UnresolvedPredicateError, message: describe(reason)
  end

  defp describe({:unresolved, kind, name, :definitions}) do
    "cannot resolve #{kind} #{inspect(name)}: the provided definitions have no such #{kind}"
  end

  defp describe({:unresolved, kind, name, module}) do
    "cannot resolve #{kind} #{inspect(name)}: #{inspect(module)} has no such #{kind}"
  end

  defp describe({:no_source, name}) do
    "cannot resolve reference #{inspect(name)}: no module context and no default pipeline " <>
      "is configured (config :riffle, :default_pipeline)"
  end

  defp describe({:invalid_ref, kind, ref}) do
    "invalid #{kind} reference: #{inspect(ref)}"
  end

  defp describe({:cycle, kind, path}) do
    "circular #{kind} reference: #{Enum.map_join(path, " -> ", &inspect/1)}"
  end
end
