defmodule Riffle.Ctx.Perturbation.InputReceived do
  @moduledoc """
  A source has supplied the run's input. The payload is opaque to the waist.
  """

  @behaviour Riffle.Ctx.Perturbation.Kind

  @enforce_keys [:payload]
  defstruct [:payload]

  @type t :: %__MODULE__{payload: term()}

  @impl true
  def tag, do: :input_received
end
