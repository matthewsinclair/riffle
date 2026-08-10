defmodule Riffle.Ctx.Emission.OutputProduced do
  @moduledoc """
  The run produced its output.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:payload]
  defstruct [:payload]

  @type t :: %__MODULE__{payload: term()}

  @impl true
  def tag, do: :output_produced
end
