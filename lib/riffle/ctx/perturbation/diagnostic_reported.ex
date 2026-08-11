defmodule Riffle.Ctx.Perturbation.DiagnosticReported do
  @moduledoc """
  A source reports something worth noticing that is not an error.

  `level` says how much it matters and `message` is the text.

  Through the knot it changes no state and yields a
  `Riffle.Ctx.Emission.Diagnostic`. Nothing about the run is different for
  having been remarked upon, which is exactly why this is separate from
  `Riffle.Ctx.Perturbation.ErrorReported` -- a diagnostic that quietly
  accumulated into the error list would make a talkative run look like a
  failing one.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:level, :message]
  defstruct [:level, :message]

  @type t :: %__MODULE__{level: atom(), message: String.t()}

  @impl true
  def tag, do: :diagnostic_reported
end
