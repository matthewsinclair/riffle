defmodule Riffle.Ctx.Emission.Diagnostic do
  @moduledoc """
  Something worth noticing happened, and it was not an error.

  `level` says how much it matters and `message` is the text.

  Yielded by `Riffle.Ctx.Perturbation.DiagnosticReported`. Deliberately not a
  log call: the waist is pure, so a remark is a value in the emission stream
  and what to do with it belongs to whoever is reading.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:level, :message]
  defstruct [:level, :message]

  @type t :: %__MODULE__{level: atom(), message: String.t()}

  @impl true
  def tag, do: :diagnostic
end
