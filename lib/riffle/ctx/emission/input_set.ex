defmodule Riffle.Ctx.Emission.InputSet do
  @moduledoc """
  The run's input was set.

  `payload` is the ingested items.

  Yielded by `Riffle.Ctx.Perturbation.InputReceived`, carrying the same value
  that was written to the context's input slot.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:payload]
  defstruct [:payload]

  @type t :: %__MODULE__{payload: term()}

  @impl true
  def tag, do: :input_set
end
