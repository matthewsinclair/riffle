defmodule Riffle.Ctx.Catalog do
  @moduledoc """
  THE catalog mechanism, and the contract every typed I/O type implements.

  Both registries -- `Riffle.Ctx.Perturbation` and `Riffle.Ctx.Emission` -- are
  the same machine over a different membership list: a closed list of struct
  modules, a compile-time tag-to-module map, and a lookup that loud-fails on a
  tag the list does not declare. That machine lives here once. Each registry
  contributes only what is genuinely its own: which types it holds, and the
  union type they form.

  Duplicate tags are a compile-time error rather than a test-time one. Two types
  claiming one tag would collapse into a single map entry, and a closed registry
  that quietly lost a member is worse than no registry at all.
  """

  @doc "The routing tag this type dispatches on. Unique within its catalog."
  @callback tag() :: atom()

  @doc """
  Builds a registry over a closed list of implementations.

      use Riffle.Ctx.Catalog, implementations: [Perturbation.RunStarted, ...]
  """
  defmacro __using__(implementations: implementations) do
    quote do
      @implementations unquote(implementations)
      @by_tag Map.new(@implementations, &{&1.tag(), &1})

      @duplicate_tags @implementations
                      |> Enum.group_by(& &1.tag())
                      |> Enum.filter(fn {_tag, modules} -> length(modules) > 1 end)

      if @duplicate_tags != [] do
        raise ArgumentError,
              "duplicate tags in #{inspect(__MODULE__)}: #{inspect(@duplicate_tags)} -- " <>
                "a catalog tag identifies exactly one type"
      end

      @doc "The closed set of modules in this catalog."
      @spec implementations() :: [module()]
      def implementations, do: @implementations

      @doc "Every declared tag."
      @spec tags() :: [atom()]
      def tags, do: Map.keys(@by_tag)

      @doc """
      Resolves a tag to its module.

      Returns `:error` for a tag this catalog does not declare -- the membership
      set is closed, so an unrecognised tag is a fact the caller must handle,
      never a silent miss.
      """
      @spec fetch_by_tag(atom()) :: {:ok, module()} | :error
      def fetch_by_tag(tag) when is_atom(tag), do: Map.fetch(@by_tag, tag)
    end
  end
end
