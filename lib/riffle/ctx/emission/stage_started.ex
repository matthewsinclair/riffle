defmodule Riffle.Ctx.Emission.StageStarted do
  @moduledoc """
  A named stage of work began.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:stage]
  defstruct [:stage]

  @type t :: %__MODULE__{stage: atom()}

  @impl true
  def tag, do: :stage_started
end
