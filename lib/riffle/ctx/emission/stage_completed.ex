defmodule Riffle.Ctx.Emission.StageCompleted do
  @moduledoc """
  A named stage finished, carrying what it produced.
  """

  @behaviour Riffle.Ctx.Emission.Kind

  @enforce_keys [:stage, :output]
  defstruct [:stage, :output]

  @type t :: %__MODULE__{stage: atom(), output: term()}

  @impl true
  def tag, do: :stage_completed
end
