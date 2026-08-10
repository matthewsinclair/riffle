defmodule Riffle.Ctx.Perturbation.RunStarted do
  @moduledoc """
  A source has begun a run. The knot transitions the context out of `:pending`.
  """

  @behaviour Riffle.Ctx.Perturbation.Kind

  defstruct []

  @type t :: %__MODULE__{}

  @impl true
  def tag, do: :run_started
end
