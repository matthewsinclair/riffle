defmodule Riffle.Ctx.Perturbation.StageExited do
  @moduledoc """
  A source has left a named stage, carrying what the stage produced.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:stage, :output]
  defstruct [:stage, :output]

  @type t :: %__MODULE__{stage: atom(), output: term()}

  @impl true
  def tag, do: :stage_exited
end
