defmodule Riffle.Predicate.Registry do
  @moduledoc """
  Registry for storing and accessing predicate definitions.

  This module provides a centralized registry for storing and accessing
  predicate, loop, and pipeline definitions. It allows for registering
  definitions both from compile-time macro modules and runtime-loaded
  DSL files.
  """

  use GenServer

  alias Riffle.Predicate.Dsl.Loader

  @registry_name __MODULE__

  # Client API

  @doc """
  Starts the registry process.

  ## Options
    * `:name` - The name to register the registry process under (default: #{inspect(@registry_name)})

  ## Examples

      # Start with default name
      {:ok, pid} = Registry.start_link()

      # Start with custom name
      {:ok, pid} = Registry.start_link(name: MyRegistry)
  """
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, @registry_name)
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  @doc """
  Registers compiled predicate modules in the registry.

  ## Parameters
    * `module` - Module containing compiled predicate definitions using `Riffle.Predicate.Dsl.Macro`
    * `server` - The registry server pid or name (default: #{inspect(@registry_name)})

  ## Examples

      Registry.register_module(MyPredicates)
  """
  def register_module(module, server \\ @registry_name) do
    GenServer.call(server, {:register_module, module})
  end

  @doc """
  Loads predicate definitions from a file into the registry.

  ## Parameters
    * `path` - Path to the .pred file
    * `server` - The registry server pid or name (default: #{inspect(@registry_name)})

  ## Examples

      Registry.load_file("predicates/user_signals.pred")
  """
  def load_file(path, server \\ @registry_name) do
    GenServer.call(server, {:load_file, path})
  end

  @doc """
  Loads predicate definitions from a directory into the registry.

  ## Parameters
    * `dir_path` - Path to the directory containing .pred files
    * `recursive` - Whether to search subdirectories (default: true)
    * `server` - The registry server pid or name (default: #{inspect(@registry_name)})

  ## Examples

      Registry.load_directory("predicates")
  """
  def load_directory(dir_path, recursive \\ true, server \\ @registry_name) do
    GenServer.call(server, {:load_directory, dir_path, recursive})
  end

  @doc """
  Gets a predicate function by name from the registry.

  ## Parameters
    * `name` - Name of the predicate
    * `server` - The registry server pid or name (default: #{inspect(@registry_name)})

  ## Examples

      predicate_fn = Registry.get_predicate(:active)
      result = predicate_fn.(item)
  """
  def get_predicate(name, server \\ @registry_name) do
    GenServer.call(server, {:get_predicate, name})
  end

  @doc """
  Gets a loop by name from the registry.

  ## Parameters
    * `name` - Name of the loop
    * `server` - The registry server pid or name (default: #{inspect(@registry_name)})

  ## Examples

      loop = Registry.get_loop(:user_signals)
      filtered_items = Riffle.Predicate.Loop.filter(loop, items)
  """
  def get_loop(name, server \\ @registry_name) do
    GenServer.call(server, {:get_loop, name})
  end

  @doc """
  Gets a pipeline by name from the registry.

  ## Parameters
    * `name` - Name of the pipeline
    * `server` - The registry server pid or name (default: #{inspect(@registry_name)})

  ## Examples

      pipeline = Registry.get_pipeline(:user_pipeline)
      filtered_items = Riffle.Predicate.Pipeline.filter(pipeline, items)
  """
  def get_pipeline(name, server \\ @registry_name) do
    GenServer.call(server, {:get_pipeline, name})
  end

  @doc """
  Lists all registered predicates.

  ## Parameters
    * `server` - The registry server pid or name (default: #{inspect(@registry_name)})

  ## Examples

      predicates = Registry.list_predicates()
      # => [:active, :premium, :trial, ...]
  """
  def list_predicates(server \\ @registry_name) do
    GenServer.call(server, :list_predicates)
  end

  @doc """
  Lists all registered loops.

  ## Parameters
    * `server` - The registry server pid or name (default: #{inspect(@registry_name)})

  ## Examples

      loops = Registry.list_loops()
      # => [:user_signals, :trial_signals, ...]
  """
  def list_loops(server \\ @registry_name) do
    GenServer.call(server, :list_loops)
  end

  @doc """
  Lists all registered pipelines.

  ## Parameters
    * `server` - The registry server pid or name (default: #{inspect(@registry_name)})

  ## Examples

      pipelines = Registry.list_pipelines()
      # => [:user_pipeline, :trial_pipeline, ...]
  """
  def list_pipelines(server \\ @registry_name) do
    GenServer.call(server, :list_pipelines)
  end

  @doc """
  Clears all registrations from the registry.

  ## Parameters
    * `server` - The registry server pid or name (default: #{inspect(@registry_name)})

  ## Examples

      Registry.clear()
  """
  def clear(server \\ @registry_name) do
    GenServer.call(server, :clear)
  end

  # Server callbacks

  @impl true
  def init(:ok) do
    state = %{
      predicates: %{},
      loops: %{},
      pipelines: %{}
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:get_predicate, name}, _from, state) do
    with {:ok, predicate} <- fetch_predicate(name, state) do
      {:reply, {:ok, create_callable_predicate(predicate)}, state}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:get_loop, name}, _from, state) do
    with {:ok, loop} <- fetch_loop(name, state),
         {:ok, loop_struct} <- ensure_loop_struct(loop, state) do
      {:reply, {:ok, loop_struct}, state}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:get_pipeline, name}, _from, state) do
    with {:ok, pipeline} <- fetch_pipeline(name, state),
         {:ok, pipeline_struct} <- ensure_pipeline_struct(pipeline, state) do
      {:reply, {:ok, pipeline_struct}, state}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:list_predicates, _from, state) do
    predicates = Map.keys(state.predicates)
    {:reply, predicates, state}
  end

  @impl true
  def handle_call(:list_loops, _from, state) do
    loops = Map.keys(state.loops)
    {:reply, loops, state}
  end

  @impl true
  def handle_call(:list_pipelines, _from, state) do
    pipelines = Map.keys(state.pipelines)
    {:reply, pipelines, state}
  end

  @impl true
  def handle_call(:clear, _from, _state) do
    new_state = %{
      predicates: %{},
      loops: %{},
      pipelines: %{}
    }

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:register_module, module}, _from, state) do
    # Extract predicate, loop, and pipeline maps from the module
    try do
      # Get module's predicates
      predicates = apply(module, :predicates, [])

      # Generate predicate instances
      predicate_instances =
        predicates
        |> Enum.map(fn {name, _definition} -> {name, apply(module, name, [])} end)
        |> Map.new()

      # Get module's loops
      loops = apply(module, :loops, [])

      # Generate loop instances
      loop_instances =
        loops
        |> Enum.map(fn {name, _definition} -> {name, apply(module, name, [])} end)
        |> Map.new()

      # Get module's pipelines
      pipelines = apply(module, :pipelines, [])

      # Generate pipeline instances
      pipeline_instances =
        pipelines
        |> Enum.map(fn {name, _definition} -> {name, apply(module, name, [])} end)
        |> Map.new()

      instances = %{
        predicates: predicate_instances,
        loops: loop_instances,
        pipelines: pipeline_instances
      }

      {:reply, :ok, merge_instances(state, instances)}
    rescue
      error ->
        {:reply, {:error, {:module_registration_error, module, error}}, state}
    end
  end

  @impl true
  def handle_call({:load_file, path}, _from, state) do
    register_loaded(state, Loader.load_file(path))
  end

  @impl true
  def handle_call({:load_directory, dir_path, recursive}, _from, state) do
    register_loaded(state, Loader.load_directory(dir_path, recursive))
  end

  # Private helper functions for better structure

  @spec fetch_predicate(atom(), map()) :: {:ok, map()} | {:error, tuple()}
  defp fetch_predicate(name, state) do
    case Map.fetch(state.predicates, name) do
      {:ok, predicate} -> {:ok, predicate}
      :error -> {:error, {:not_found, :predicate, name}}
    end
  end

  @spec fetch_loop(atom(), map()) :: {:ok, map()} | {:error, tuple()}
  defp fetch_loop(name, state) do
    case Map.fetch(state.loops, name) do
      {:ok, loop} -> {:ok, loop}
      :error -> {:error, {:not_found, :loop, name}}
    end
  end

  @spec fetch_pipeline(atom(), map()) :: {:ok, map()} | {:error, tuple()}
  defp fetch_pipeline(name, state) do
    case Map.fetch(state.pipelines, name) do
      {:ok, pipeline} -> {:ok, pipeline}
      :error -> {:error, {:not_found, :pipeline, name}}
    end
  end

  @spec create_callable_predicate(map()) :: function()
  defp create_callable_predicate(%{function: _function} = predicate) do
    fn item ->
      {matched, _} = Riffle.Predicate.evaluate(predicate, item)
      matched
    end
  end

  defp create_callable_predicate(predicate), do: predicate

  @spec merge_instances(map(), map()) :: map()
  defp merge_instances(state, instances) do
    %{
      predicates: Map.merge(state.predicates, instances.predicates),
      loops: Map.merge(state.loops, instances.loops),
      pipelines: Map.merge(state.pipelines, instances.pipelines)
    }
  end

  @spec register_loaded(map(), {:ok, map()} | {:error, term()}) ::
          {:reply, :ok | {:error, term()}, map()}
  defp register_loaded(state, {:ok, definitions}) do
    case Loader.create_instances(definitions) do
      {:ok, instances} -> {:reply, :ok, merge_instances(state, instances)}
      {:error, reason} -> {:reply, {:error, {:instance_creation_error, reason}}, state}
    end
  end

  defp register_loaded(state, {:error, reason}), do: {:reply, {:error, reason}, state}

  # Reference resolution goes through registry state; a name with no
  # registered definition is a tagged error, never a synthesised stand-in.
  # (The previous shape stubbed missing predicates as always-true -- matching
  # and tagging every item -- and missing loops as empty, silently.)
  @spec ensure_loop_struct(struct() | map(), map()) ::
          {:ok, Riffle.Predicate.Loop.t() | term()} | {:error, term()}
  defp ensure_loop_struct(%Riffle.Predicate.Loop{} = loop, _state), do: {:ok, loop}

  defp ensure_loop_struct(%{name: name, description: description, predicates: predicates}, state) do
    with {:ok, resolved} <- resolve_predicates(predicates, state) do
      {:ok, Riffle.Predicate.Loop.new(name, description, resolved)}
    end
  end

  defp ensure_loop_struct(loop, _state), do: {:ok, loop}

  @spec ensure_pipeline_struct(struct() | map(), map()) ::
          {:ok, Riffle.Predicate.Pipeline.t() | term()} | {:error, term()}
  defp ensure_pipeline_struct(%Riffle.Predicate.Pipeline{} = pipeline, _state),
    do: {:ok, pipeline}

  defp ensure_pipeline_struct(%{name: name, description: description, loops: loops}, state) do
    with {:ok, resolved} <- resolve_loops(loops, state) do
      {:ok, Riffle.Predicate.Pipeline.new(name, description, resolved)}
    end
  end

  defp ensure_pipeline_struct(pipeline, _state), do: {:ok, pipeline}

  @spec resolve_predicates([map()], map()) :: {:ok, [map()]} | {:error, term()}
  defp resolve_predicates(predicates, state) do
    predicates
    |> Enum.reduce_while({:ok, []}, fn
      %{function: _} = pred, {:ok, acc} ->
        {:cont, {:ok, [pred | acc]}}

      %{body: _} = pred, {:ok, acc} ->
        {:cont, {:ok, [pred | acc]}}

      %{name: pred_name}, {:ok, acc} ->
        case Map.fetch(state.predicates, pred_name) do
          {:ok, pred} -> {:cont, {:ok, [pred | acc]}}
          :error -> {:halt, {:error, {:unresolved, :predicate, pred_name}}}
        end

      other, {:ok, _acc} ->
        {:halt, {:error, {:invalid_predicate, other}}}
    end)
    |> finish_resolution()
  end

  @spec resolve_loops([map()], map()) :: {:ok, [term()]} | {:error, term()}
  defp resolve_loops(loops, state) do
    loops
    |> Enum.reduce_while({:ok, []}, fn
      %Riffle.Predicate.Loop{} = loop, {:ok, acc} ->
        {:cont, {:ok, [loop | acc]}}

      %{predicates: _} = loop_map, {:ok, acc} ->
        case ensure_loop_struct(loop_map, state) do
          {:ok, loop} -> {:cont, {:ok, [loop | acc]}}
          {:error, reason} -> {:halt, {:error, reason}}
        end

      %{name: loop_name}, {:ok, acc} ->
        with {:ok, loop_def} <- fetch_loop(loop_name, state),
             {:ok, loop} <- ensure_loop_struct(loop_def, state) do
          {:cont, {:ok, [loop | acc]}}
        else
          {:error, reason} -> {:halt, {:error, reason}}
        end

      other, {:ok, _acc} ->
        {:halt, {:error, {:invalid_loop, other}}}
    end)
    |> finish_resolution()
  end

  @spec finish_resolution({:ok, [term()]} | {:error, term()}) ::
          {:ok, [term()]} | {:error, term()}
  defp finish_resolution({:ok, acc}), do: {:ok, Enum.reverse(acc)}
  defp finish_resolution({:error, _} = error), do: error
end
