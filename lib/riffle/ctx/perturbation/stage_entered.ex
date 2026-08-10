defmodule Riffle.Ctx.Perturbation.StageEntered do
  @moduledoc """
  A source has entered a named stage of work.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:stage]
  defstruct [:stage]

  @type t :: %__MODULE__{stage: atom()}

  @impl true
  def tag, do: :stage_entered
end
