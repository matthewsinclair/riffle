defmodule Riffle.Ctx.Emission.InputSet do
  @moduledoc """
  The run's input was set to the carried payload.
  """

  @behaviour Riffle.Ctx.Emission.Kind

  @enforce_keys [:payload]
  defstruct [:payload]

  @type t :: %__MODULE__{payload: term()}

  @impl true
  def tag, do: :input_set
end
