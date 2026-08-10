defmodule Riffle.Predicate.Dsl.Statements do
  @moduledoc """
  THE statement-shape ladder for DSL blocks.

  Both DSL front ends -- the compile-time macros (`Riffle.Predicate.Dsl.Macro`)
  and the runtime parser (`Riffle.Predicate.Dsl.Parser`) -- accept the same
  block grammar: a loop block holds predicate references or inline predicate
  definitions; a pipeline block holds loop references or inline loop
  definitions. This module owns that grammar in one place; the front ends
  differ only in the context words their raise messages carry.

  An unrecognised statement always raises `ArgumentError`: a silently dropped
  reference changes what a loop or pipeline matches with no signal.
  """

  # Context -> {location phrase, container phrase} for raise messages. The
  # texts are pinned verbatim by the loader and macro suites.
  @contexts %{
    defloop: {"defloop", "a defloop block"},
    defpipeline: {"defpipeline", "a defpipeline block"},
    loop_block: {"a loop block", "a loop"},
    pipeline_block: {"a pipeline block", "a pipeline"}
  }

  @type context :: :defloop | :defpipeline | :loop_block | :pipeline_block

  @doc """
  Normalises a `do`-block body to its statement list.

  A multi-statement body carries `{:__block__, _, statements}`; a single
  statement stands alone.
  """
  @spec block_statements(Macro.t()) :: [Macro.t()]
  def block_statements({:__block__, _meta, statements}), do: statements
  def block_statements(statement), do: [statement]

  @doc """
  Extracts predicate references and inline predicate definitions from a loop
  body. Raises `ArgumentError` -- with `context` naming the location -- for
  any statement that is neither.
  """
  @spec predicates!(Macro.t(), context()) :: [map()]
  def predicates!(body, context) do
    body |> block_statements() |> Enum.flat_map(&predicate_statement(&1, context))
  end

  @doc """
  Extracts loop references and inline loop definitions from a pipeline body.
  Inline loop bodies recurse through `predicates!/2` carrying
  `predicate_context`. Raises `ArgumentError` for anything else.
  """
  @spec loops!(Macro.t(), context(), context()) :: [map()]
  def loops!(body, context, predicate_context) do
    body
    |> block_statements()
    |> Enum.flat_map(&loop_statement(&1, context, predicate_context))
  end

  # References: predicate :name / predicate(:name)
  defp predicate_statement({:predicate, _, [{name, _, nil}]}, _context) when is_atom(name) do
    [%{name: name, inline: false}]
  end

  defp predicate_statement({:predicate, _, [name]}, _context) when is_atom(name) do
    [%{name: name, inline: false}]
  end

  # Inline definitions, with and without a description
  defp predicate_statement({:predicate, _, [{name, _, nil}, description, [do: body]]}, _context)
       when is_atom(name) and is_binary(description) do
    [%{name: name, description: description, body: body, inline: true}]
  end

  defp predicate_statement({:predicate, _, [{name, _, nil}, [do: body]]}, _context)
       when is_atom(name) do
    [%{name: name, description: "", body: body, inline: true}]
  end

  defp predicate_statement({:predicate, _, [name, description, [do: body]]}, _context)
       when is_atom(name) and is_binary(description) do
    [%{name: name, description: description, body: body, inline: true}]
  end

  defp predicate_statement({:predicate, _, [name, [do: body]]}, _context) when is_atom(name) do
    [%{name: name, description: "", body: body, inline: true}]
  end

  defp predicate_statement(statement, context) do
    raise ArgumentError, unrecognised(statement, context, "predicate")
  end

  # References: loop :name / loop(:name)
  defp loop_statement({:loop, _, [{name, _, nil}]}, _context, _pc) when is_atom(name) do
    [%{name: name, inline: false}]
  end

  defp loop_statement({:loop, _, [name]}, _context, _pc) when is_atom(name) do
    [%{name: name, inline: false}]
  end

  # Inline definitions, with and without a description
  defp loop_statement({:loop, _, [{name, _, nil}, description, [do: body]]}, _context, pc)
       when is_atom(name) and is_binary(description) do
    [%{name: name, description: description, predicates: predicates!(body, pc), inline: true}]
  end

  defp loop_statement({:loop, _, [{name, _, nil}, [do: body]]}, _context, pc)
       when is_atom(name) do
    [%{name: name, description: "", predicates: predicates!(body, pc), inline: true}]
  end

  defp loop_statement({:loop, _, [name, description, [do: body]]}, _context, pc)
       when is_atom(name) and is_binary(description) do
    [%{name: name, description: description, predicates: predicates!(body, pc), inline: true}]
  end

  defp loop_statement({:loop, _, [name, [do: body]]}, _context, pc) when is_atom(name) do
    [%{name: name, description: "", predicates: predicates!(body, pc), inline: true}]
  end

  defp loop_statement(statement, context, _predicate_context) do
    raise ArgumentError, unrecognised(statement, context, "loop")
  end

  defp unrecognised(statement, context, kind) do
    {location, container} = Map.fetch!(@contexts, context)

    "unrecognised statement in #{location}: `#{Macro.to_string(statement)}` " <>
      "-- #{container} may contain only #{kind} references " <>
      "(#{kind} :name) or inline #{kind} definitions"
  end
end
