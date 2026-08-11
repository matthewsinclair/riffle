defmodule Riffle.Ctx.Emission.StageCompleted do
  @moduledoc """
  A named stage finished, and here is what survived it.

  `stage` is the stage's own name; `output` is the items themselves.

  Yielded by `Riffle.Ctx.Perturbation.StageExited`.

  This is the evidence behind the claim in
  `Riffle.Ctx.Emission.StageProgress`, and it is what a summary of a run
  should be built from. A per-stage tally kept separately from these would be
  a second answer capable of disagreeing with the first.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:stage, :output]
  defstruct [:stage, :output]

  @type t :: %__MODULE__{stage: atom(), output: term()}

  @impl true
  def tag, do: :stage_completed
end
