defmodule Riffle.Ctx.Perturbation.ErrorReported do
  @moduledoc """
  A source reports an error that does not end the run.

  `error` is the failure itself, in whatever shape the source uses.

  Through the knot it appends `error` to the context's errors and yields a
  `Riffle.Ctx.Emission.ErrorRaised`. The status is untouched -- that is the
  whole difference from `Riffle.Ctx.Perturbation.RunFailed`, which reports an
  error the run does not survive.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:error]
  defstruct [:error]

  @type t :: %__MODULE__{error: term()}

  @impl true
  def tag, do: :error_reported
end
