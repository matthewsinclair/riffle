defmodule Riffle.Ctx.Emission.StageStarted do
  @moduledoc """
  A named stage began.

  `stage` is the stage's own name.

  Yielded by `Riffle.Ctx.Perturbation.StageEntered`. No state changed to
  produce it.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:stage]
  defstruct [:stage]

  @type t :: %__MODULE__{stage: atom()}

  @impl true
  def tag, do: :stage_started
end
