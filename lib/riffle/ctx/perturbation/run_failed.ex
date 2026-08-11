defmodule Riffle.Ctx.Perturbation.RunFailed do
  @moduledoc """
  A source announces that a run cannot continue, and says why.

  `reason` is the failure itself, in whatever shape the source uses for
  failures.

  Through the knot it appends `reason` to the context's errors, moves the
  status to `:failed`, and yields a `Riffle.Ctx.Emission.StatusChanged` plus a
  `Riffle.Ctx.Emission.ErrorRaised`. One perturbation rather than two: a
  separate error report first would record the same failure twice.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:reason]
  defstruct [:reason]

  @type t :: %__MODULE__{reason: term()}

  @impl true
  def tag, do: :run_failed
end
