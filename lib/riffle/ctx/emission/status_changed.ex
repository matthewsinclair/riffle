defmodule Riffle.Ctx.Emission.StatusChanged do
  @moduledoc """
  The run's status changed.

  `from` and `to` are the statuses either side of the change, so a reader can
  reconstruct the whole status history from the emission stream without
  holding the context.

  Yielded by every perturbation that moves the run's status:
  `Riffle.Ctx.Perturbation.RunStarted`, `RunCompleted` and `RunFailed`.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:from, :to]
  defstruct [:from, :to]

  @type t :: %__MODULE__{from: Riffle.Ctx.status(), to: Riffle.Ctx.status()}

  @impl true
  def tag, do: :status_changed
end
