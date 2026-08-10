defmodule Riffle.Ctx.Emission.StageProgress do
  @moduledoc """
  A named stage reported progress.
  """

  @behaviour Riffle.Ctx.Emission.Kind

  @enforce_keys [:stage, :progress]
  defstruct [:stage, :progress]

  @type t :: %__MODULE__{stage: atom(), progress: term()}

  @impl true
  def tag, do: :stage_progress
end
