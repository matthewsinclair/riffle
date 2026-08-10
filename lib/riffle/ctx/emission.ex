defmodule Riffle.Ctx.Emission do
  @moduledoc """
  THE closed registry of typed outputs from the knot.

  Every emission is a struct declaring a tag (`Riffle.Ctx.Emission.Kind`) and a
  typespec, enumerated here in a closed list with the tag-to-module map built at
  compile time. An unknown tag returns `:error`.

  Emission payloads are opaque to the waist. A result travels as a `term()` the
  waist never inspects, so the waist has no reason to name an engine type and
  cannot grow a dependency on one -- fenced in
  `test/riffle/ctx/boundary_fence_test.exs`.
  """

  alias Riffle.Ctx.Emission

  @implementations [
    Emission.DefaultPassed,
    Emission.Diagnostic,
    Emission.ErrorRaised,
    Emission.InputSet,
    Emission.MetadataSet,
    Emission.OutputProduced,
    Emission.StageCompleted,
    Emission.StageProgress,
    Emission.StageStarted,
    Emission.StatusChanged
  ]

  @by_tag Map.new(@implementations, &{&1.tag(), &1})

  @type t ::
          Emission.DefaultPassed.t()
          | Emission.Diagnostic.t()
          | Emission.ErrorRaised.t()
          | Emission.InputSet.t()
          | Emission.MetadataSet.t()
          | Emission.OutputProduced.t()
          | Emission.StageCompleted.t()
          | Emission.StageProgress.t()
          | Emission.StageStarted.t()
          | Emission.StatusChanged.t()

  @doc "The closed set of emission modules."
  @spec implementations() :: [module()]
  def implementations, do: @implementations

  @doc "Every declared tag."
  @spec tags() :: [atom()]
  def tags, do: Map.keys(@by_tag)

  @doc """
  Resolves a tag to its module.

  Returns `:error` for a tag the catalog does not declare.
  """
  @spec fetch_by_tag(atom()) :: {:ok, module()} | :error
  def fetch_by_tag(tag) when is_atom(tag), do: Map.fetch(@by_tag, tag)
end
