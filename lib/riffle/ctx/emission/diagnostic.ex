defmodule Riffle.Ctx.Emission.Diagnostic do
  @moduledoc """
  A diagnostic left the waist for whatever consumer wants it.
  """

  @behaviour Riffle.Ctx.Emission.Kind

  @enforce_keys [:level, :message]
  defstruct [:level, :message]

  @type t :: %__MODULE__{level: atom(), message: String.t()}

  @impl true
  def tag, do: :diagnostic
end
