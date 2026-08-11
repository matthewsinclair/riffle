defmodule Riffle.Ctx.Perturbation.RunStarted do
  @moduledoc """
  A source announces that a run has begun.

  Carries nothing: beginning is the whole of the message.

  Through the knot it moves the context to `:running` and yields a
  `Riffle.Ctx.Emission.StatusChanged`. It is the first perturbation of a run,
  and the only one that changes status without also carrying a result.
  """

  @behaviour Riffle.Ctx.Catalog

  defstruct []

  @type t :: %__MODULE__{}

  @impl true
  def tag, do: :run_started
end
