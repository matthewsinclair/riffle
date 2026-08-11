defmodule Riffle.Ctx.Emission.ErrorRaised do
  @moduledoc """
  An error was reported against the run.

  `error` is the failure itself, in whatever shape the source uses.

  Yielded by both `Riffle.Ctx.Perturbation.ErrorReported` and
  `Riffle.Ctx.Perturbation.RunFailed` -- the emission is the same either way,
  and what separates a survivable error from a fatal one is the
  `Riffle.Ctx.Emission.StatusChanged` that accompanies the fatal one.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:error]
  defstruct [:error]

  @type t :: %__MODULE__{error: term()}

  @impl true
  def tag, do: :error_raised
end
