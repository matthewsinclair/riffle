defmodule Riffle.Ctx.Perturbation.RunFailed do
  @moduledoc """
  A source has ended a run unsuccessfully, carrying the reason.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:reason]
  defstruct [:reason]

  @type t :: %__MODULE__{reason: term()}

  @impl true
  def tag, do: :run_failed
end
