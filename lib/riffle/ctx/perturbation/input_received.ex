defmodule Riffle.Ctx.Perturbation.InputReceived do
  @moduledoc """
  A source hands the run its input.

  `payload` is the ingested items, not the raw material they were built from,
  so a run can be replayed from the context alone.

  Through the knot it writes `payload` into the context's input slot and yields
  a `Riffle.Ctx.Emission.InputSet` carrying the same value.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:payload]
  defstruct [:payload]

  @type t :: %__MODULE__{payload: term()}

  @impl true
  def tag, do: :input_received
end
