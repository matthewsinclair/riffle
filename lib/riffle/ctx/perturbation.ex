defmodule Riffle.Ctx.Perturbation do
  @moduledoc """
  THE closed registry of typed inputs to the knot.

  Every perturbation is a struct declaring a tag (`Riffle.Ctx.Perturbation.Kind`)
  and a typespec. This module enumerates them in a closed list and builds the
  tag-to-module map at compile time, so lookup is a map read and an unknown tag
  returns `:error` rather than falling through to something plausible.

  Adding a type is a deliberate two-step ritual -- author the struct module under
  `Riffle.Ctx.Perturbation.*`, then add it to `@implementations`. The catalog
  never grows silently, and the bijection fence
  (`test/riffle/ctx/catalog_fence_test.exs`) fails the build if the two steps
  come apart.
  """

  alias Riffle.Ctx.Perturbation

  @implementations [
    Perturbation.DiagnosticReported,
    Perturbation.ErrorReported,
    Perturbation.InputReceived,
    Perturbation.MetadataRecorded,
    Perturbation.RunCompleted,
    Perturbation.RunFailed,
    Perturbation.RunStarted,
    Perturbation.StageEntered,
    Perturbation.StageExited,
    Perturbation.StageProgressed
  ]

  @by_tag Map.new(@implementations, &{&1.tag(), &1})

  @type t ::
          Perturbation.DiagnosticReported.t()
          | Perturbation.ErrorReported.t()
          | Perturbation.InputReceived.t()
          | Perturbation.MetadataRecorded.t()
          | Perturbation.RunCompleted.t()
          | Perturbation.RunFailed.t()
          | Perturbation.RunStarted.t()
          | Perturbation.StageEntered.t()
          | Perturbation.StageExited.t()
          | Perturbation.StageProgressed.t()

  @doc "The closed set of perturbation modules."
  @spec implementations() :: [module()]
  def implementations, do: @implementations

  @doc "Every declared tag."
  @spec tags() :: [atom()]
  def tags, do: Map.keys(@by_tag)

  @doc """
  Resolves a tag to its module.

  Returns `:error` for a tag the catalog does not declare -- the membership set
  is closed, so an unrecognised tag is a fact the caller must handle, never a
  silent miss.
  """
  @spec fetch_by_tag(atom()) :: {:ok, module()} | :error
  def fetch_by_tag(tag) when is_atom(tag), do: Map.fetch(@by_tag, tag)
end
