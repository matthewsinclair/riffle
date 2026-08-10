defmodule Riffle.Predicate.Dsl.Parser do
  @moduledoc """
  Parses DSL text into structured definition maps.

  Text becomes AST via `parse/1`; `extract_definitions!/1` walks the top-level
  statements in one pass and buckets each into predicates, loops, or
  pipelines. Statement-shape knowledge for loop and pipeline blocks lives in
  `Riffle.Predicate.Dsl.Statements`, shared with the compile-time macros.

  The parser supports three predicate syntax formats:
  1. `fn` syntax: an anonymous function
  2. `call` syntax: a reference to an existing function
  3. `expr` syntax: the simple expression language

  StandardLib functions can be accessed using the STD alias, which is bound
  where bodies evaluate (`Riffle.Predicate.create/1`):
  ```
  predicate(:unsubscribed, "Users who have unsubscribed") do
    call &STD.Boolean.is_false/1, ["subscribed"]
  end
  ```
  """

  alias Riffle.Predicate.Dsl.Statements

  @type parsing_result :: {:ok, term()} | {:error, term()}
  @type predicate_def :: %{name: atom(), description: String.t(), body: term()}
  @type predicate_ref :: %{name: atom(), inline: boolean()} | predicate_def
  @type loop_def :: %{name: atom(), description: String.t(), predicates: [predicate_ref()]}
  @type loop_ref :: %{name: atom(), inline: boolean()} | loop_def
  @type pipeline_def :: %{name: atom(), description: String.t(), loops: [loop_ref()]}
  @type definitions :: %{
          predicates: [predicate_def()],
          loops: [loop_def()],
          pipelines: [pipeline_def()]
        }

  @doc """
  Parses a string containing DSL definitions.

  ## Parameters
    * `content` - String containing DSL definitions

  ## Returns
    * `{:ok, ast}` or `{:error, reason}`
  """
  @spec parse(String.t()) :: parsing_result()
  def parse(content) when is_binary(content) do
    {:ok, Code.string_to_quoted!(content)}
  rescue
    e -> {:error, e}
  end

  @doc """
  Buckets every top-level statement of parsed DSL into its definition list.

  A top-level statement must be a predicate, loop, or pipeline definition.
  Anything else raises `ArgumentError`: a misspelled definition that
  silently vanished would change what a pipeline matches with no signal.
  This one dispatch is both the extractor and the completeness check, so
  the two can never drift apart.
  """
  @spec extract_definitions!(term()) :: definitions()
  def extract_definitions!(ast) do
    buckets =
      ast
      |> Statements.block_statements()
      |> Enum.reduce(%{predicates: [], loops: [], pipelines: []}, &bucket_statement/2)

    %{
      predicates: Enum.reverse(buckets.predicates),
      loops: Enum.reverse(buckets.loops),
      pipelines: Enum.reverse(buckets.pipelines)
    }
  end

  # Predicate definitions, with and without a description
  defp bucket_statement({:predicate, _, [{name, _, nil}, description, [do: body]]}, acc)
       when is_atom(name) and is_binary(description) do
    prepend(acc, :predicates, %{name: name, description: description, body: body})
  end

  defp bucket_statement({:predicate, _, [{name, _, nil}, [do: body]]}, acc) when is_atom(name) do
    prepend(acc, :predicates, %{name: name, description: "", body: body})
  end

  defp bucket_statement({:predicate, _, [name, description, [do: body]]}, acc)
       when is_atom(name) and is_binary(description) do
    prepend(acc, :predicates, %{name: name, description: description, body: body})
  end

  defp bucket_statement({:predicate, _, [name, [do: body]]}, acc) when is_atom(name) do
    prepend(acc, :predicates, %{name: name, description: "", body: body})
  end

  # Loop definitions; block shapes resolve through the shared ladder
  defp bucket_statement({:loop, _, [{name, _, nil}, description, [do: body]]}, acc)
       when is_atom(name) and is_binary(description) do
    prepend(acc, :loops, loop_def(name, description, body))
  end

  defp bucket_statement({:loop, _, [{name, _, nil}, [do: body]]}, acc) when is_atom(name) do
    prepend(acc, :loops, loop_def(name, "", body))
  end

  defp bucket_statement({:loop, _, [name, description, [do: body]]}, acc)
       when is_atom(name) and is_binary(description) do
    prepend(acc, :loops, loop_def(name, description, body))
  end

  defp bucket_statement({:loop, _, [name, [do: body]]}, acc) when is_atom(name) do
    prepend(acc, :loops, loop_def(name, "", body))
  end

  # Pipeline definitions
  defp bucket_statement({:pipeline, _, [{name, _, nil}, description, [do: body]]}, acc)
       when is_atom(name) and is_binary(description) do
    prepend(acc, :pipelines, pipeline_def(name, description, body))
  end

  defp bucket_statement({:pipeline, _, [{name, _, nil}, [do: body]]}, acc) when is_atom(name) do
    prepend(acc, :pipelines, pipeline_def(name, "", body))
  end

  defp bucket_statement({:pipeline, _, [name, description, [do: body]]}, acc)
       when is_atom(name) and is_binary(description) do
    prepend(acc, :pipelines, pipeline_def(name, description, body))
  end

  defp bucket_statement({:pipeline, _, [name, [do: body]]}, acc) when is_atom(name) do
    prepend(acc, :pipelines, pipeline_def(name, "", body))
  end

  defp bucket_statement(statement, _acc) do
    raise ArgumentError,
          "unrecognised top-level statement: `#{Macro.to_string(statement)}` " <>
            "-- DSL content may contain only predicate, loop, and pipeline definitions"
  end

  defp loop_def(name, description, body) do
    %{
      name: name,
      description: description,
      predicates: Statements.predicates!(body, :loop_block)
    }
  end

  defp pipeline_def(name, description, body) do
    %{
      name: name,
      description: description,
      loops: Statements.loops!(body, :pipeline_block, :loop_block)
    }
  end

  defp prepend(acc, kind, definition), do: Map.update!(acc, kind, &[definition | &1])
end
