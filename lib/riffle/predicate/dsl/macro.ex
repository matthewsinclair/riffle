defmodule Riffle.Predicate.Dsl.Macro do
  @moduledoc """
  Provides macros for compile-time definition of predicates, loops, and pipelines.

  This module contains macros that can be used within Elixir modules to define
  predicate processing components at compile-time, offering better performance
  and compile-time validation compared to runtime parsing.

  ## Usage

  ```elixir
  defmodule MyPredicates do
    use Riffle.Predicate.Dsl.Macro

    # Define a predicate
    defpredicate :active, "Active users" do
      fn item -> item.fields["status"] == "active" end
    end

    # Define a loop with predicate references
    defloop :user_signals, "User signal detection" do
      predicate :active
      predicate :premium
    end

    # Define a pipeline with loop references
    defpipeline :user_pipeline, "User processing pipeline" do
      loop :user_signals
      loop :conversion_signals
    end
  end
  ```
  """

  @doc """
  Imports macros for predicate, loop, and pipeline definitions.

  When using this module, the following macros are imported:
  - `defpredicate/3` - Define a named predicate
  - `defloop/3` - Define a named loop containing predicates
  - `defpipeline/3` - Define a named pipeline containing loops
  """
  defmacro __using__(_opts) do
    quote do
      import Riffle.Predicate.Dsl.Macro,
        only: [
          defpredicate: 2,
          defpredicate: 3,
          defloop: 2,
          defloop: 3,
          defpipeline: 2,
          defpipeline: 3,
          expr: 1
        ]

      alias Riffle.Predicate.StandardLib, as: STD

      Module.register_attribute(__MODULE__, :predicates, accumulate: true)
      Module.register_attribute(__MODULE__, :loops, accumulate: true)
      Module.register_attribute(__MODULE__, :pipelines, accumulate: true)

      @before_compile Riffle.Predicate.Dsl.Macro
    end
  end

  @doc """
  Generates predicate, loop, and pipeline accessor functions at compile time.

  This macro runs before the module is compiled and generates:
  - predicates/0 - Returns a map of all defined predicates
  - loops/0 - Returns a map of all defined loops
  - pipelines/0 - Returns a map of all defined pipelines
  - get_predicate/1 - Returns a specific predicate by name
  - get_loop/1 - Returns a specific loop by name
  - get_pipeline/1 - Returns a specific pipeline by name
  """
  defmacro __before_compile__(env) do
    # The three get_* accessors are injected ONLY when the module has not
    # already defined them, and that condition is the whole fix.
    #
    # __before_compile__ runs AFTER the module body, so anything generated here
    # lands as a LATER clause than the module's own. A module that also does
    # `use Riffle.Predicate.DefaultPipelineConfig` -- which defines the same
    # three inline, at `use` time -- therefore received these as dead clauses
    # sitting behind ones that already matched every atom. Silent on Elixir
    # 1.18; three "the following clause is redundant" warnings on 1.20.
    #
    # They were not harmless duplicates. DefaultPipelineConfig's get_pipeline/1
    # resolves the name with `apply(__MODULE__, name, [])` and yields a
    # %Riffle.Predicate.Pipeline{} struct, where the clause below yields the
    # plain map held in pipelines(). Different values from the same call, and
    # the unreachable one was this one.
    #
    # Modules that use the DSL on its own (standard_lib and the DSL test
    # modules) define no accessors of their own, so they still get all three.
    # Dropping them outright would have broken those; asking first does not.
    get_predicate =
      unless Module.defines?(env.module, {:get_predicate, 1}) do
        quote do
          @doc """
          Returns a specific predicate by name.
          """
          def get_predicate(name) when is_atom(name) do
            Map.get(predicates(), name)
          end
        end
      end

    get_loop =
      unless Module.defines?(env.module, {:get_loop, 1}) do
        quote do
          @doc """
          Returns a specific loop by name.
          """
          def get_loop(name) when is_atom(name) do
            Map.get(loops(), name)
          end
        end
      end

    get_pipeline =
      unless Module.defines?(env.module, {:get_pipeline, 1}) do
        quote do
          @doc """
          Returns a specific pipeline by name.
          """
          def get_pipeline(name) when is_atom(name) do
            Map.get(pipelines(), name)
          end
        end
      end

    quote do
      @doc """
      Returns a map of all predicates defined in this module.
      """
      def predicates, do: Map.new(@predicates)

      @doc """
      Returns a map of all loops defined in this module.
      """
      def loops, do: Map.new(@loops)

      @doc """
      Returns a map of all pipelines defined in this module.
      """
      def pipelines, do: Map.new(@pipelines)

      unquote(get_predicate)
      unquote(get_loop)
      unquote(get_pipeline)
    end
  end

  @doc """
  Creates an expression-based predicate.

  This macro enables the use of simplified field access syntax in predicate definitions.
  It supports the @field_name syntax for accessing fields in the item being processed.

  ## Examples

      defpredicate :active, "Active users" do
        expr @status == "active"
      end
      
      defpredicate :high_activity, "High-activity users" do
        expr to_integer(@login_count) > 50
      end
  """
  defmacro expr(expression) do
    # When used directly in code, we keep the structure simple for pattern matching
    quote do
      {:expr, unquote(Macro.escape(expression))}
    end
  end

  @doc """
  Defines a named predicate function at compile-time.

  ## Parameters
    * `name` - Atom name for the predicate
    * `body` - Function body for the predicate

  ## Examples
      defpredicate :active do
        fn item -> item.fields["status"] == "active" end
      end
  """
  defmacro defpredicate(name, do: body) do
    quote do
      defpredicate(unquote(name), "", do: unquote(body))
    end
  end

  @doc """
  Defines a named predicate function with description at compile-time.

  ## Parameters
    * `name` - Atom name for the predicate
    * `description` - String description of the predicate's purpose
    * `body` - Function body for the predicate

  ## Examples
      defpredicate :active, "Identifies active users" do
        fn item -> item.fields["status"] == "active" end
      end
  """
  defmacro defpredicate(name, description, do: body) when is_binary(description) do
    # Check if the body has the form of an expr call
    # This directly handles the pattern without trying to expand nested macros
    predicate_body =
      case body do
        # Pattern match when body is an expr call - extract the expression directly
        {:expr, _, [expr]} ->
          # Convert the expr pattern to the internal {:expr, expr} format that Predicate.create/1 expects
          quoted_expr = quote do: {:expr, unquote(Macro.escape(expr))}
          quoted_expr

        # Default case - use the body as is
        _ ->
          Macro.escape(body)
      end

    quote do
      predicate_name = unquote(name)
      predicate_description = unquote(description)

      @predicates {predicate_name,
                   %{
                     name: predicate_name,
                     description: predicate_description,
                     body: unquote(predicate_body)
                   }}

      # Generate a function that returns this predicate object
      def unquote(name)() do
        # Create a predicate function from the body
        # Use predicate_body directly - we've already processed it above
        fn_impl = Riffle.Predicate.create(unquote(predicate_body))

        # Create the final predicate definition
        Riffle.Predicate.new(unquote(name), unquote(description), fn_impl)
      end
    end
  end

  @doc """
  Defines a named loop at compile-time.

  ## Parameters
    * `name` - Atom name for the loop
    * `predicates_block` - Block containing predicate references

  ## Examples
      defloop :user_signals do
        predicate :active
        predicate :premium
      end
  """
  defmacro defloop(name, do: predicates_block) do
    quote do
      defloop(unquote(name), "", do: unquote(predicates_block))
    end
  end

  @doc """
  Defines a named loop with description at compile-time.

  ## Parameters
    * `name` - Atom name for the loop
    * `description` - String description of the loop's purpose
    * `predicates_block` - Block containing predicate references

  ## Examples
      defloop :user_signals, "Detects user-related signals" do
        predicate :active
        predicate :premium
      end
  """
  defmacro defloop(name, description, do: predicates_block) when is_binary(description) do
    # Process the predicates block
    predicates =
      case predicates_block do
        {:__block__, _, statements} ->
          Macro.escape(extract_predicates_from_block(statements))

        {function, meta, args} ->
          Macro.escape(extract_predicates_from_block([{function, meta, args}]))
      end

    quote do
      loop_name = unquote(name)
      loop_description = unquote(description)
      loop_predicates = unquote(predicates)

      @loops {loop_name,
              %{
                name: loop_name,
                description: loop_description,
                predicates: loop_predicates
              }}

      # Generate a function that returns this loop struct, with every
      # reference resolved and every body hydrated to a callable exactly
      # once, here -- not per item at evaluation time.
      def unquote(name)() do
        Riffle.Predicate.Resolver.resolve_loop!(__MODULE__, %{
          name: unquote(name),
          description: unquote(description),
          predicates: unquote(predicates)
        })
      end
    end
  end

  @doc """
  Defines a named pipeline at compile-time.

  ## Parameters
    * `name` - Atom name for the pipeline
    * `loops_block` - Block containing loop references

  ## Examples
      defpipeline :user_pipeline do
        loop :user_signals
        loop :conversion_signals
      end
  """
  defmacro defpipeline(name, do: loops_block) do
    quote do
      defpipeline(unquote(name), "", do: unquote(loops_block))
    end
  end

  @doc """
  Defines a named pipeline with description at compile-time.

  ## Parameters
    * `name` - Atom name for the pipeline
    * `description` - String description of the pipeline's purpose
    * `loops_block` - Block containing loop references

  ## Examples
      defpipeline :user_pipeline, "Processes user data through signal pipeline" do
        loop :user_signals
        loop :conversion_signals
      end
  """
  defmacro defpipeline(name, description, do: loops_block) when is_binary(description) do
    # Process the loops block
    loops =
      case loops_block do
        {:__block__, _, statements} ->
          Macro.escape(extract_loops_from_block(statements))

        {function, meta, args} ->
          Macro.escape(extract_loops_from_block([{function, meta, args}]))
      end

    quote do
      pipeline_name = unquote(name)
      pipeline_description = unquote(description)
      pipeline_loops = unquote(loops)

      @pipelines {pipeline_name,
                  %{
                    name: pipeline_name,
                    description: pipeline_description,
                    loops: pipeline_loops
                  }}

      # Generate a function that returns this pipeline struct, with loop
      # references resolved and hydrated recursively.
      def unquote(name)() do
        Riffle.Predicate.Resolver.resolve_pipeline!(__MODULE__, %{
          name: unquote(name),
          description: unquote(description),
          loops: unquote(loops)
        })
      end
    end
  end

  # Helper functions for constructing predicate and loop references
  # These are used at macro expansion time

  @doc false
  def extract_predicates_from_block(statements) do
    Enum.flat_map(statements, &extract_predicate/1)
  end

  @doc false
  defp extract_predicate({:predicate, _, [{name, _, nil}]}) do
    [%{name: name, inline: false}]
  end

  @doc false
  defp extract_predicate({:predicate, _, [name]}) when is_atom(name) do
    [%{name: name, inline: false}]
  end

  @doc false
  defp extract_predicate({:predicate, _, [{name, _, nil}, description, [do: body]]})
       when is_binary(description) do
    [%{name: name, description: description, body: body, inline: true}]
  end

  @doc false
  defp extract_predicate({:predicate, _, [{name, _, nil}, [do: body]]}) do
    [%{name: name, description: "", body: body, inline: true}]
  end

  @doc false
  defp extract_predicate({:predicate, _, [name, description, [do: body]]})
       when is_binary(description) do
    [%{name: name, description: description, body: body, inline: true}]
  end

  @doc false
  defp extract_predicate({:predicate, _, [name, [do: body]]}) when is_atom(name) do
    [%{name: name, description: "", body: body, inline: true}]
  end

  @doc false
  defp extract_predicate({:predicate, _, [{name, _, nil}, description, [do: {:expr, _, [expr]}]]})
       when is_binary(description) do
    [%{name: name, description: description, body: {:expr, expr}, inline: true}]
  end

  @doc false
  defp extract_predicate({:predicate, _, [{name, _, nil}, [do: {:expr, _, [expr]}]]}) do
    [%{name: name, description: "", body: {:expr, expr}, inline: true}]
  end

  @doc false
  defp extract_predicate({:predicate, _, [name, description, [do: {:expr, _, [expr]}]]})
       when is_binary(description) do
    [%{name: name, description: description, body: {:expr, expr}, inline: true}]
  end

  @doc false
  defp extract_predicate({:predicate, _, [name, [do: {:expr, _, [expr]}]]}) when is_atom(name) do
    [%{name: name, description: "", body: {:expr, expr}, inline: true}]
  end

  # An unrecognised statement inside a defloop block fails the build: a
  # silently dropped predicate changes what the loop matches with no signal.
  defp extract_predicate(statement) do
    raise ArgumentError,
          "unrecognised statement in defloop: `#{Macro.to_string(statement)}` " <>
            "-- a defloop block may contain only predicate references " <>
            "(predicate :name) or inline predicate definitions"
  end

  @doc false
  def extract_loops_from_block(statements) do
    Enum.flat_map(statements, &extract_loop/1)
  end

  @doc false
  defp extract_loop({:loop, _, [{name, _, nil}]}) do
    [%{name: name, inline: false}]
  end

  @doc false
  defp extract_loop({:loop, _, [name]}) when is_atom(name) do
    [%{name: name, inline: false}]
  end

  @doc false
  defp extract_loop({:loop, _, [{name, _, nil}, description, [do: body]]})
       when is_binary(description) do
    predicates = extract_predicates_from_block(block_to_statements(body))
    [%{name: name, description: description, predicates: predicates, inline: true}]
  end

  @doc false
  defp extract_loop({:loop, _, [{name, _, nil}, [do: body]]}) do
    predicates = extract_predicates_from_block(block_to_statements(body))
    [%{name: name, description: "", predicates: predicates, inline: true}]
  end

  @doc false
  defp extract_loop({:loop, _, [name, description, [do: body]]}) when is_binary(description) do
    predicates = extract_predicates_from_block(block_to_statements(body))
    [%{name: name, description: description, predicates: predicates, inline: true}]
  end

  @doc false
  defp extract_loop({:loop, _, [name, [do: body]]}) when is_atom(name) do
    predicates = extract_predicates_from_block(block_to_statements(body))
    [%{name: name, description: "", predicates: predicates, inline: true}]
  end

  # Same contract as extract_predicate/1: defpipeline blocks hold only loop
  # statements, and anything else fails the build.
  defp extract_loop(statement) do
    raise ArgumentError,
          "unrecognised statement in defpipeline: `#{Macro.to_string(statement)}` " <>
            "-- a defpipeline block may contain only loop references " <>
            "(loop :name) or inline loop definitions"
  end

  @doc false
  defp block_to_statements({:__block__, _, statements}), do: statements
  defp block_to_statements(statement), do: [statement]
end
