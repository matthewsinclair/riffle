defmodule Riffle.Ctx.Perturbation.StageEntered do
  @moduledoc """
  A source reports that it has begun a named stage.

  `stage` is the stage's own name. Where stages come from loops -- as in
  `Riffle.Sia` -- it is the loop's name, and nothing derives it from tags or
  from position in a sequence.

  Through the knot it changes no state and yields a
  `Riffle.Ctx.Emission.StageStarted`. Entering is an announcement, not a
  transition: nothing about the run is different for having started a stage.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:stage]
  defstruct [:stage]

  @type t :: %__MODULE__{stage: atom()}

  @impl true
  def tag, do: :stage_entered
end
