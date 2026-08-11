defmodule Riffle.Ctx.Perturbation.StageProgressed do
  @moduledoc """
  A source reports progress within a stage it has entered.

  `stage` is the stage's own name. `progress` is deliberately open -- the waist
  does not know what progress means for any particular source, and a type that
  guessed would be wrong for the next one. `Riffle.Sia` puts a survivor count
  here.

  Through the knot it changes no state and yields a
  `Riffle.Ctx.Emission.StageProgress`.

  Distinguish it from `Riffle.Ctx.Perturbation.StageExited`, which carries the
  stage's actual output. Progress is a claim *about* results; exit carries the
  results. A reader checking the first against the second is what makes the
  claim falsifiable.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:stage, :progress]
  defstruct [:stage, :progress]

  @type t :: %__MODULE__{stage: atom(), progress: term()}

  @impl true
  def tag, do: :stage_progressed
end
