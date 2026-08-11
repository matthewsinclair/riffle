defmodule Riffle.Ctx.Emission.DefaultPassed do
  @moduledoc """
  The delivery floor: a perturbation the knot has no clause for, surfaced rather than swallowed.

  `perturbation_tag` is the catalog tag of whatever arrived, and `reason` says
  why it reached the floor -- `:unhandled` is currently the only one.

  Nothing yields this deliberately. It exists so that a perturbation added to
  the catalog without a matching transition becomes a visible fact instead of
  a silent no-op, and `test/riffle/delivery_floor_fence_test.exs` enumerates
  the catalog to make sure the gap is caught at build time rather than
  discovered in a stream. Seeing one at runtime means a catalog member has no
  clause in `Riffle.Ctx.Knot`.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:perturbation_tag, :reason]
  defstruct [:perturbation_tag, :reason]

  @type t :: %__MODULE__{perturbation_tag: atom(), reason: atom()}

  @impl true
  def tag, do: :default_passed
end
