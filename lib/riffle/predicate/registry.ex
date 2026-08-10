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
  alias Riffle.Predicate.Resolver

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
  Gets a hydrated predicate definition by name from the registry.

  ## Parameters
    * `name` - Name of the predicate
    * `server` - The registry server pid or name (default: #{inspect(@registry_name)})

  ## Examples

      {:ok, predicate} = Registry.get_predicate(:active)
      {matched, tagged_item} = Riffle.Predicate.evaluate(predicate, item)
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

      {:ok, loop} = Registry.get_loop(:user_signals)
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

      {:ok, pipeline} = Registry.get_pipeline(:user_pipeline)
      filtered_items = Riffle.Predicate.Pipeline.process(pipeline, items)
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

  # Reference resolution goes through the Resolver with the registry state as
  # the definitions source; a name with no registered definition is a tagged
  # {:unresolved, ...} error, never a synthesised stand-in.

  @impl true
  def handle_call({:get_predicate, name}, _from, state) do
    {:reply, Resolver.resolve_predicate(state, %{name: name, inline: false}), state}
  end

  @impl true
  def handle_call({:get_loop, name}, _from, state) do
    {:reply, Resolver.resolve_loop(state, %{name: name, inline: false}), state}
  end

  @impl true
  def handle_call({:get_pipeline, name}, _from, state) do
    {:reply, Resolver.resolve_pipeline(state, %{name: name, inline: false}), state}
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
    # Each DSL module exposes its definitions by kind, and a generated
    # zero-arity function per name that returns the resolved instance.
    instances = %{
      predicates: instances_of(module, module.predicates()),
      loops: instances_of(module, module.loops()),
      pipelines: instances_of(module, module.pipelines())
    }

    {:reply, :ok, merge_instances(state, instances)}
  rescue
    # A module that does not answer the DSL contract is a caller error, not a
    # registry crash: it is reported to that caller and the registry lives on.
    error ->
      {:reply, {:error, {:module_registration_error, module, error}}, state}
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

  # The generated accessor is named for the definition, so the name is only
  # known at runtime -- apply/3 is the call, not a shortcut around one.
  @spec instances_of(module(), map()) :: map()
  defp instances_of(module, definitions) do
    Map.new(definitions, fn {name, _definition} -> {name, apply(module, name, [])} end)
  end

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
end
