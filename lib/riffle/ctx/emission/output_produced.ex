defmodule Riffle.Ctx.Emission.OutputProduced do
  @moduledoc """
  The run produced its results.

  `payload` is the results themselves.

  Yielded by `Riffle.Ctx.Perturbation.RunCompleted`, alongside the
  `Riffle.Ctx.Emission.StatusChanged` that marks the run complete, and carrying
  the same value that was written to the context's output slot. A completed
  run's results therefore appear in three places that must agree: here, in the
  context, and in the final stage's `Riffle.Ctx.Emission.StageCompleted`.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:payload]
  defstruct [:payload]

  @type t :: %__MODULE__{payload: term()}

  @impl true
  def tag, do: :output_produced
end
