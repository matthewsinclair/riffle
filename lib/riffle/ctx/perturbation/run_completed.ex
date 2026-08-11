defmodule Riffle.Ctx.Perturbation.RunCompleted do
  @moduledoc """
  A source announces that a run has finished, and hands over its results.

  `output` is the run's results themselves, not a count or a flag describing
  them.

  Through the knot it writes `output` into the context, moves the status to
  `:completed`, and yields both a `Riffle.Ctx.Emission.StatusChanged` and a
  `Riffle.Ctx.Emission.OutputProduced` carrying the same value.

  That the results travel with the announcement is deliberate, and it is the
  D2 defect made structurally impossible: the source layer this project
  replaced recorded that results were available and discarded the results in
  the same breath. Here there is no way to say "completed" without saying
  "with these".
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:output]
  defstruct [:output]

  @type t :: %__MODULE__{output: term()}

  @impl true
  def tag, do: :run_completed
end
