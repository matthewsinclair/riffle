defmodule Riffle.Ctx.Emission.StatusChanged do
  @moduledoc """
  The run's status moved. A transition is a fact the knot reports, never a setter a caller drives.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:from, :to]
  defstruct [:from, :to]

  @type t :: %__MODULE__{from: Riffle.Ctx.status(), to: Riffle.Ctx.status()}

  @impl true
  def tag, do: :status_changed
end
