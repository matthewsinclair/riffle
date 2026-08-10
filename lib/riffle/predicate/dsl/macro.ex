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

  alias Riffle.Predicate.Dsl.Statements

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
    accessors =
      Enum.map(
        [{:get_predicate, :predicates}, {:get_loop, :loops}, {:get_pipeline, :pipelines}],
        fn {accessor, collection} -> accessor(env, accessor, collection) end
      )

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

      unquote_splicing(accessors)
    end
  end

  # An accessor is injected ONLY when the module has not already defined it,
  # and that condition is the whole fix.
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
  # %Riffle.Predicate.Pipeline{} struct, where the clause here yields the
  # plain map held in pipelines(). Different values from the same call, and
  # the unreachable one was this one.
  #
  # Modules that use the DSL on its own (standard_lib and the DSL test
  # modules) define no accessors of their own, so they still get all three.
  # Dropping them outright would have broken those; asking first does not.
  defp accessor(env, accessor, collection) do
    case Module.defines?(env.module, {accessor, 1}) do
      true ->
        nil

      false ->
        quote do
          @doc """
          Returns a specific #{unquote(collection)} entry by name.
          """
          def unquote(accessor)(name) when is_atom(name) do
            Map.get(unquote(collection)(), name)
          end
        end
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
    predicates = Macro.escape(Statements.predicates!(predicates_block, :defloop))

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
    loops = Macro.escape(Statements.loops!(loops_block, :defpipeline, :defloop))

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
end
