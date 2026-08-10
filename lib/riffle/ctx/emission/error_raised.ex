defmodule Riffle.Ctx.Emission.ErrorRaised do
  @moduledoc """
  An error was accumulated against the run.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:error]
  defstruct [:error]

  @type t :: %__MODULE__{error: term()}

  @impl true
  def tag, do: :error_raised
end
