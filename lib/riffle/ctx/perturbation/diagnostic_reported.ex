defmodule Riffle.Ctx.Perturbation.DiagnosticReported do
  @moduledoc """
  A source has produced a diagnostic. The waist never writes it anywhere -- a consumer realises it.
  """

  @behaviour Riffle.Ctx.Perturbation.Kind

  @enforce_keys [:level, :message]
  defstruct [:level, :message]

  @type t :: %__MODULE__{level: atom(), message: String.t()}

  @impl true
  def tag, do: :diagnostic_reported
end
