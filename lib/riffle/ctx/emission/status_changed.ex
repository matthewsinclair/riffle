defmodule Riffle.Ctx.Emission.StatusChanged do
  @moduledoc """
  The run's status moved. A transition is a fact the knot reports, never a setter a caller drives.
  """

  @behaviour Riffle.Ctx.Emission.Kind

  @enforce_keys [:from, :to]
  defstruct [:from, :to]

  @type t :: %__MODULE__{from: atom(), to: atom()}

  @impl true
  def tag, do: :status_changed
end
