defmodule Riffle.Ctx.Emission.StageProgress do
  @moduledoc """
  A named stage reported progress.

  `stage` is the stage's own name; `progress` is whatever progress means to
  the source that reported it -- `Riffle.Sia` puts a survivor count here.

  Yielded by `Riffle.Ctx.Perturbation.StageProgressed`.

  This is a claim about a stage. `Riffle.Ctx.Emission.StageCompleted` carries
  that stage's actual output, so the claim can be checked rather than
  believed: in a well-formed run the count reported here equals the length of
  the output that follows.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:stage, :progress]
  defstruct [:stage, :progress]

  @type t :: %__MODULE__{stage: atom(), progress: term()}

  @impl true
  def tag, do: :stage_progress
end
