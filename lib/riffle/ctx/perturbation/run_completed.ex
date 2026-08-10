defmodule Riffle.Ctx.Perturbation.RunCompleted do
  @moduledoc """
  A source has finished a run successfully, carrying the run's product.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:output]
  defstruct [:output]

  @type t :: %__MODULE__{output: term()}

  @impl true
  def tag, do: :run_completed
end
