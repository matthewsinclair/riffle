defmodule Riffle.Ctx.Perturbation.StageProgressed do
  @moduledoc """
  A source reports progress within a stage it has entered.
  """

  @behaviour Riffle.Ctx.Perturbation.Kind

  @enforce_keys [:stage, :progress]
  defstruct [:stage, :progress]

  @type t :: %__MODULE__{stage: atom(), progress: term()}

  @impl true
  def tag, do: :stage_progressed
end
