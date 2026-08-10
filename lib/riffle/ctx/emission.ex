defmodule Riffle.Ctx.Emission do
  @moduledoc """
  THE closed registry of typed outputs from the knot.

  Every emission is a struct declaring a tag (`Riffle.Ctx.Catalog`) and a
  typespec. The registry mechanism lives once in `Riffle.Ctx.Catalog`; this
  module contributes only its membership and the union type those types form.

  Emission payloads are opaque to the waist. A result travels as a `term()` the
  waist never inspects, so the waist has no reason to name an engine type and
  cannot grow a dependency on one -- fenced in
  `test/riffle/ctx/boundary_fence_test.exs`.
  """

  alias Riffle.Ctx.Emission

  use Riffle.Ctx.Catalog,
    implementations: [
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
end
