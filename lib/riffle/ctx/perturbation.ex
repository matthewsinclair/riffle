defmodule Riffle.Ctx.Perturbation do
  @moduledoc """
  THE closed registry of typed inputs to the knot.

  Every perturbation is a struct declaring a tag (`Riffle.Ctx.Catalog`) and a
  typespec. The registry mechanism -- closed list, compile-time tag map, loud
  lookup -- lives once in `Riffle.Ctx.Catalog`; this module contributes only its
  membership and the union type those types form.

  Adding a type is a deliberate two-step ritual -- author the struct module under
  `Riffle.Ctx.Perturbation.*`, then add it to `@implementations`. The catalog
  never grows silently, and the bijection fence
  (`test/riffle/ctx/catalog_fence_test.exs`) fails the build if the two steps
  come apart.
  """

  alias Riffle.Ctx.Perturbation

  use Riffle.Ctx.Catalog,
    implementations: [
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
end
