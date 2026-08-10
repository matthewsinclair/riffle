defmodule Riffle.Predicate.Dsl.Loader do
  @moduledoc """
  Loads predicate DSL definitions from files.

  This module provides functions for loading predicate, loop, and pipeline definitions
  from .pred files, allowing for runtime configuration of predicate pipelines.
  """

  alias Riffle.Predicate.Dsl.Parser
  alias Riffle.Predicate.Dsl.Evaluator

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
    # Add aliases for StandardLib to provide simplified access in DSL
    content_with_aliases = """
    alias Riffle.Predicate.StandardLib, as: STD
    alias Riffle.Predicate.Dsl.STD

    #{content}
    """

    with {:ok, ast} <- Parser.parse(content_with_aliases) do
      predicates = Parser.extract_predicates(ast)
      loops = Parser.extract_loops(ast)
      pipelines = Parser.extract_pipelines(ast)

      {:ok, %{predicates: predicates, loops: loops, pipelines: pipelines}}
    end
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
  filtered_items = Riffle.Predicate.Pipeline.filter(user_pipeline, items)
  ```
  """
  @spec create_instances(map()) :: loading_result()
  def create_instances(%{predicates: predicates, loops: loops, pipelines: pipelines}) do
    try do
      # Create predicates first
      predicate_instances =
        predicates
        |> Enum.map(fn pred ->
          predicate_fn = create_predicate_function(pred.body)
          {pred.name, Riffle.Predicate.new(pred.name, pred.description || "", predicate_fn)}
        end)
        |> Map.new()

      # Then create loops referencing predicates
      loop_instances =
        loops
        |> Enum.map(fn loop ->
          loop_predicates =
            Enum.map(loop.predicates, fn
              %{name: pred_name, inline: false} ->
                Map.get(predicate_instances, pred_name)

              %{name: pred_name, body: body, description: description} ->
                fn_impl = create_predicate_function(body)
                Riffle.Predicate.new(pred_name, description || "", fn_impl)

              %{name: pred_name, body: body} ->
                fn_impl = create_predicate_function(body)
                Riffle.Predicate.new(pred_name, "", fn_impl)
            end)

          loop_instance =
            Riffle.Predicate.Loop.new(loop.name, loop.description || "", loop_predicates)

          {loop.name, loop_instance}
        end)
        |> Map.new()

      # Finally create pipelines referencing loops
      pipeline_instances =
        pipelines
        |> Enum.map(fn pipeline ->
          pipeline_loops =
            Enum.map(pipeline.loops, fn
              %{name: loop_name, inline: false} ->
                Map.get(loop_instances, loop_name)

              %{name: loop_name, predicates: predicates} = loop_def ->
                # Handle inline loop definition
                loop_predicates =
                  Enum.map(predicates, fn
                    %{name: pred_name, inline: false} ->
                      Map.get(predicate_instances, pred_name)

                    %{body: body} ->
                      create_predicate_function(body)
                  end)

                Riffle.Predicate.Loop.new(
                  loop_name,
                  Map.get(loop_def, :description, ""),
                  loop_predicates
                )
            end)

          pipeline_instance =
            Riffle.Predicate.Pipeline.new(
              pipeline.name,
              pipeline.description || "",
              pipeline_loops
            )

          {pipeline.name, pipeline_instance}
        end)
        |> Map.new()

      {:ok,
       %{predicates: predicate_instances, loops: loop_instances, pipelines: pipeline_instances}}
    rescue
      e -> {:error, {:instance_creation_error, e}}
    end
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

  defp create_predicate_function({:expr, _, [expr]}) do
    # Handle expression syntax
    expr_str = Macro.to_string(expr)

    case Evaluator.parse(expr_str) do
      {:ok, function} -> function
      {:error, error} -> raise "Error parsing expression: #{inspect(error)}"
    end
  end

  defp create_predicate_function({:call, module, function}) do
    # Handle call syntax
    module_func = Module.concat(Elixir, module)
    function_atom = String.to_atom(function)
    apply(module_func, function_atom, [])
  end

  defp create_predicate_function(ast) do
    # Handle fn syntax (anonymous functions)
    {predicate_fn, _} = Code.eval_quoted(ast)
    predicate_fn
  end
end
