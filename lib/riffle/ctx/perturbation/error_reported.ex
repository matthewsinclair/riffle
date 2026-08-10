defmodule Riffle.Ctx.Perturbation.ErrorReported do
  @moduledoc """
  A source has observed an error. The run accumulates it; it does not vanish.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:error]
  defstruct [:error]

  @type t :: %__MODULE__{error: term()}

  @impl true
  def tag, do: :error_reported
end
