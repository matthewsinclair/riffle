defmodule Riffle.Predicate.Dsl.Loader do
  @moduledoc """
  Loads predicate DSL definitions from files.

  This module provides functions for loading predicate, loop, and pipeline definitions
  from .pred files, allowing for runtime configuration of predicate pipelines.
  """

  alias Riffle.Predicate.Dsl.Parser
  alias Riffle.Predicate.Resolver

  @type loading_result :: {:ok, map()} | {:error, term()}

  @doc """
  Loads a string containing DSL definitions.

  ## Parameters
    * `content` - String containing DSL definitions

  ## Returns
    * `{:ok, %{predicates: [...], loops: [...], pipelines: [...]}}` on success
    * `{:error, reason}` on failure

  ## Examples

  ```elixir
  {:ok, definitions} = Loader.load_string("predicate(:active, \"Active users\") do ...")
  ```
  """
  @spec load_string(String.t()) :: loading_result()
  def load_string(content) when is_binary(content) do
    # THE one STD name is bound at body evaluation (Predicate.create/1's
    # eval aliases), so .pred content can write STD.Boolean.is_true("active")
    # and friends with no alias statement of its own.
    with {:ok, ast} <- Parser.parse(content) do
      {:ok, Parser.extract_definitions!(ast)}
    end
  rescue
    # DSL content is user input: an unrecognised statement -- top-level or
    # in-block -- raised during extraction surfaces as a tagged error at this
    # boundary, message intact.
    e in ArgumentError ->
      {:error, {:invalid_dsl, Exception.message(e)}}
  end

  @doc """
  Loads a .pred file and extracts all definitions.

  ## Parameters
    * `path` - Path to the .pred file

  ## Returns
    * `{:ok, %{predicates: [...], loops: [...], pipelines: [...]}}` on success
    * `{:error, reason}` on failure

  ## Examples

  ```elixir
  {:ok, definitions} = Loader.load_file("predicates/user_signals.pred")
  ```
  """
  @spec load_file(String.t()) :: loading_result()
  def load_file(path) do
    with {:ok, content} <- File.read(path),
         {:ok, definitions} <- load_string(content) do
      {:ok, definitions}
    else
      {:error, reason} ->
        {:error, {:file_load_error, path, reason}}
    end
  end

  @doc """
  Loads all .pred files in a directory.

  ## Parameters
    * `dir_path` - Path to the directory containing .pred files
    * `recursive` - Whether to search subdirectories (default: true)

  ## Returns
    * `{:ok, %{predicates: [...], loops: [...], pipelines: [...]}}` on success
    * `{:error, reason}` on failure

  ## Examples

  ```elixir
  {:ok, definitions} = Loader.load_directory("predicates")
  ```
  """
  @spec load_directory(String.t(), boolean()) :: loading_result()
  def load_directory(dir_path, recursive \\ true) do
    pattern = if recursive, do: "#{dir_path}/**/*.pred", else: "#{dir_path}/*.pred"

    with {:ok, files} <- find_files(pattern) do
      results = Enum.map(files, &load_file/1)
      errors = Enum.filter(results, &match?({:error, _}, &1))

      if not Enum.empty?(errors) do
        {:error, {:directory_load_errors, errors}}
      else
        merged = merge_definitions(Enum.map(results, fn {:ok, defs} -> defs end))
        {:ok, merged}
      end
    end
  end

  @doc """
  Creates runtime instances from loaded definitions.

  ## Parameters
    * `definitions` - Map containing predicates, loops, and pipelines definitions

  ## Returns
    * `{:ok, %{predicates: %{}, loops: %{}, pipelines: %{}}}` on success
    * `{:error, reason}` on failure

  ## Examples

  ```elixir
  {:ok, definitions} = Loader.load_file("predicates/user_signals.pred")
  {:ok, instances} = Loader.create_instances(definitions)

  # Access instances
  user_pipeline = instances.pipelines.user_pipeline
  filtered_items = Riffle.Predicate.Pipeline.process(user_pipeline, items)
  ```
  """
  @spec create_instances(map()) :: loading_result()
  def create_instances(%{predicates: predicates, loops: loops, pipelines: pipelines}) do
    # Instances build in dependency order -- predicates, then loops, then
    # pipelines -- each phase resolving against everything built so far. An
    # unresolved reference is a tagged error, never a nil entry.
    source0 = %{predicates: %{}, loops: %{}, pipelines: %{}}

    with {:ok, predicate_instances} <- build(predicates, source0, &Resolver.resolve_predicate/2),
         source1 = %{source0 | predicates: predicate_instances},
         {:ok, loop_instances} <- build(loops, source1, &Resolver.resolve_loop/2),
         source2 = %{source1 | loops: loop_instances},
         {:ok, pipeline_instances} <- build(pipelines, source2, &Resolver.resolve_pipeline/2) do
      {:ok,
       %{predicates: predicate_instances, loops: loop_instances, pipelines: pipeline_instances}}
    end
  rescue
    # .pred content is user input: a definition body that fails to
    # materialise surfaces as a tagged error at this boundary, message intact.
    e in ArgumentError ->
      {:error, {:invalid_predicate_body, Exception.message(e)}}
  end

  # Private helpers

  defp find_files(pattern) do
    case Path.wildcard(pattern) do
      [] -> {:error, {:no_files_found, pattern}}
      files -> {:ok, files}
    end
  end

  defp merge_definitions(definitions) do
    Enum.reduce(definitions, %{predicates: [], loops: [], pipelines: []}, fn def, acc ->
      %{
        predicates: acc.predicates ++ def.predicates,
        loops: acc.loops ++ def.loops,
        pipelines: acc.pipelines ++ def.pipelines
      }
    end)
  end

  # Each definition resolves against the instances built so far; the first
  # failure halts the build with its tagged reason.
  defp build(definitions, source, resolve) do
    Enum.reduce_while(definitions, {:ok, %{}}, fn definition, {:ok, acc} ->
      case resolve.(source, definition) do
        {:ok, instance} -> {:cont, {:ok, Map.put(acc, definition.name, instance)}}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
  end
end
