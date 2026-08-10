defmodule Riffle.Predicate.Dsl.Parser do
  @moduledoc """
  Parses DSL text into structured representations.

  This module takes DSL text as input and produces structured representations
  of predicates, loops, and pipelines that can be used to create runtime instances.

  The parser supports three predicate syntax formats:
  1. `fn` syntax: Using an anonymous function
  2. `call` syntax: Referencing an existing function
  3. `expr` syntax: Using a simple expression language

  StandardLib functions can be accessed using a simplified STD alias:
  ```
  predicate(:unsubscribed, "Users who have unsubscribed") do
    call &STD.Boolean.is_false/1, ["subscribed"]
  end
  ```
  """

  @type parsing_result :: {:ok, term()} | {:error, term()}
  @type predicate_def :: %{name: atom(), description: String.t(), body: term()}
  @type predicate_ref :: %{name: atom(), inline: boolean()} | predicate_def
  @type loop_def :: %{name: atom(), description: String.t(), predicates: [predicate_ref()]}
  @type loop_ref :: %{name: atom(), inline: boolean()} | loop_def
  @type pipeline_def :: %{name: atom(), description: String.t(), loops: [loop_ref()]}

  @doc """
  Parses a string containing DSL definitions.

  ## Parameters
    * `content` - String containing DSL definitions
    
  ## Returns
    * `{:ok, ast}` or `{:error, reason}`
  """
  @spec parse(String.t()) :: parsing_result()
  def parse(content) when is_binary(content) do
    try do
      {:ok, Code.string_to_quoted!(content)}
    rescue
      e -> {:error, e}
    end
  end

  @doc """
  Extracts predicate definitions from parsed DSL.

  ## Parameters
    * `ast` - AST from parsed DSL
    
  ## Returns
    * List of predicate definition maps with name, description, and body
  """
  @spec extract_predicates(term()) :: [predicate_def()]
  def extract_predicates({:__block__, _, statements}) do
    Enum.flat_map(statements, &extract_predicates/1)
  end

  def extract_predicates({:predicate, _, [{name, _, nil}, description, [do: body]]})
      when is_binary(description) do
    [%{name: name, description: description, body: body}]
  end

  def extract_predicates({:predicate, _, [{name, _, nil}, [do: body]]}) do
    [%{name: name, description: "", body: body}]
  end

  # Handle function call style: predicate(:name, "description") do ... end
  def extract_predicates(
        {{:., _, [{:__aliases__, _, [:predicate]}, :predicate]}, _,
         [name, description, [do: body]]}
      )
      when is_binary(description) do
    [%{name: name, description: description, body: body}]
  end

  def extract_predicates(
        {{:., _, [{:__aliases__, _, _}, :predicate]}, _, [name, description, [do: body]]}
      )
      when is_binary(description) do
    [%{name: name, description: description, body: body}]
  end

  # Function call style without aliases: predicate(:name) do ... end
  def extract_predicates({:predicate, _, [name, description, [do: body]]})
      when is_binary(description) do
    [%{name: name, description: description, body: body}]
  end

  def extract_predicates({:predicate, _, [name, [do: body]]}) do
    [%{name: name, description: "", body: body}]
  end

  def extract_predicates(_) do
    []
  end

  @doc """
  Extracts loop definitions from parsed DSL.

  ## Parameters
    * `ast` - AST from parsed DSL
    
  ## Returns
    * List of loop definition maps with name, description, and predicates
  """
  @spec extract_loops(term()) :: [loop_def()]
  def extract_loops({:__block__, _, statements}) do
    Enum.flat_map(statements, &extract_loops/1)
  end

  # DSL style: loop :name "description" do ... end
  def extract_loops({:loop, _, [{name, _, nil}, description, [do: body]]})
      when is_binary(description) do
    predicates = extract_loop_predicates(body)
    [%{name: name, description: description, predicates: predicates}]
  end

  def extract_loops({:loop, _, [{name, _, nil}, [do: body]]}) do
    predicates = extract_loop_predicates(body)
    [%{name: name, description: "", predicates: predicates}]
  end

  # Function call style: loop(:name, "description") do ... end
  def extract_loops({:loop, _, [name, description, [do: body]]}) when is_binary(description) do
    predicates = extract_loop_predicates(body)
    [%{name: name, description: description, predicates: predicates}]
  end

  def extract_loops({:loop, _, [name, [do: body]]}) do
    predicates = extract_loop_predicates(body)
    [%{name: name, description: "", predicates: predicates}]
  end

  def extract_loops(_) do
    []
  end

  @doc """
  Extracts pipeline definitions from parsed DSL.

  ## Parameters
    * `ast` - AST from parsed DSL
    
  ## Returns
    * List of pipeline definition maps with name, description, and loops
  """
  @spec extract_pipelines(term()) :: [pipeline_def()]
  def extract_pipelines({:__block__, _, statements}) do
    Enum.flat_map(statements, &extract_pipelines/1)
  end

  # DSL style: pipeline :name "description" do ... end
  def extract_pipelines({:pipeline, _, [{name, _, nil}, description, [do: body]]})
      when is_binary(description) do
    loops = extract_pipeline_loops(body)
    [%{name: name, description: description, loops: loops}]
  end

  def extract_pipelines({:pipeline, _, [{name, _, nil}, [do: body]]}) do
    loops = extract_pipeline_loops(body)
    [%{name: name, description: "", loops: loops}]
  end

  # Function call style: pipeline(:name, "description") do ... end
  def extract_pipelines({:pipeline, _, [name, description, [do: body]]})
      when is_binary(description) do
    loops = extract_pipeline_loops(body)
    [%{name: name, description: description, loops: loops}]
  end

  def extract_pipelines({:pipeline, _, [name, [do: body]]}) do
    loops = extract_pipeline_loops(body)
    [%{name: name, description: "", loops: loops}]
  end

  def extract_pipelines(_) do
    []
  end

  # Private helpers

  defp extract_loop_predicates({:__block__, _, statements}) do
    Enum.flat_map(statements, &extract_predicate_reference/1)
  end

  defp extract_loop_predicates(statement) do
    extract_predicate_reference(statement)
  end

  # Handle references: predicate :name
  defp extract_predicate_reference({:predicate, _, [{name, _, nil}]}) do
    [%{name: name, inline: false}]
  end

  # Handle function calls: predicate(:name)
  defp extract_predicate_reference({:predicate, _, [name]}) do
    [%{name: name, inline: false}]
  end

  # Handle inline definition with DSL style: predicate :name "description" do ... end
  defp extract_predicate_reference({:predicate, _, [{name, _, nil}, description, [do: body]]})
       when is_binary(description) do
    [%{name: name, description: description, body: body, inline: true}]
  end

  defp extract_predicate_reference({:predicate, _, [{name, _, nil}, [do: body]]}) do
    [%{name: name, description: "", body: body, inline: true}]
  end

  # Handle inline function call style: predicate(:name, "description") do ... end
  defp extract_predicate_reference({:predicate, _, [name, description, [do: body]]})
       when is_binary(description) do
    [%{name: name, description: description, body: body, inline: true}]
  end

  defp extract_predicate_reference({:predicate, _, [name, [do: body]]}) do
    [%{name: name, description: "", body: body, inline: true}]
  end

  # Handle expr syntax in blocks: predicate :name "description" do expr fields["status"] == "active" end
  defp extract_predicate_reference(
         {:predicate, _, [{name, _, nil}, description, [do: {:expr, _, [expr]}]]}
       )
       when is_binary(description) do
    [%{name: name, description: description, body: {:expr, expr}, inline: true}]
  end

  defp extract_predicate_reference({:predicate, _, [{name, _, nil}, [do: {:expr, _, [expr]}]]}) do
    [%{name: name, description: "", body: {:expr, expr}, inline: true}]
  end

  # Handle expr syntax in function calls: predicate(:name, "description") do expr fields["status"] == "active" end
  defp extract_predicate_reference({:predicate, _, [name, description, [do: {:expr, _, [expr]}]]})
       when is_binary(description) do
    [%{name: name, description: description, body: {:expr, expr}, inline: true}]
  end

  defp extract_predicate_reference({:predicate, _, [name, [do: {:expr, _, [expr]}]]}) do
    [%{name: name, description: "", body: {:expr, expr}, inline: true}]
  end

  defp extract_predicate_reference(_) do
    []
  end

  defp extract_pipeline_loops({:__block__, _, statements}) do
    Enum.flat_map(statements, &extract_loop_reference/1)
  end

  defp extract_pipeline_loops(statement) do
    extract_loop_reference(statement)
  end

  # Handle references: loop :name
  defp extract_loop_reference({:loop, _, [{name, _, nil}]}) do
    [%{name: name, inline: false}]
  end

  # Handle function calls: loop(:name)
  defp extract_loop_reference({:loop, _, [name]}) do
    [%{name: name, inline: false}]
  end

  # Handle inline definition with DSL style: loop :name "description" do ... end
  defp extract_loop_reference({:loop, _, [{name, _, nil}, description, [do: body]]})
       when is_binary(description) do
    predicates = extract_loop_predicates(body)
    [%{name: name, description: description, predicates: predicates, inline: true}]
  end

  defp extract_loop_reference({:loop, _, [{name, _, nil}, [do: body]]}) do
    predicates = extract_loop_predicates(body)
    [%{name: name, description: "", predicates: predicates, inline: true}]
  end

  # Handle inline function call style: loop(:name, "description") do ... end
  defp extract_loop_reference({:loop, _, [name, description, [do: body]]})
       when is_binary(description) do
    predicates = extract_loop_predicates(body)
    [%{name: name, description: description, predicates: predicates, inline: true}]
  end

  defp extract_loop_reference({:loop, _, [name, [do: body]]}) do
    predicates = extract_loop_predicates(body)
    [%{name: name, description: "", predicates: predicates, inline: true}]
  end

  defp extract_loop_reference(_) do
    []
  end
end
