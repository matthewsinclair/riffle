defmodule Riffle.Ctx.Perturbation.StageExited do
  @moduledoc """
  A source reports that a named stage is finished, and hands over what survived it.

  `stage` is the stage's own name; `output` is the items themselves.

  Through the knot it changes no state and yields a
  `Riffle.Ctx.Emission.StageCompleted` carrying both.

  The counterpart to `Riffle.Ctx.Perturbation.StageProgressed`: that one
  reports a claim about a stage, this one carries the evidence for it. Every
  progress claim in a well-formed run can be checked against the exit that
  follows it.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:stage, :output]
  defstruct [:stage, :output]

  @type t :: %__MODULE__{stage: atom(), output: term()}

  @impl true
  def tag, do: :stage_exited
end
