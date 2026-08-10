defmodule Riffle.Ctx.Emission.DefaultPassed do
  @moduledoc """
  The delivery floor. A perturbation that produced no other emission surfaces here rather than vanishing.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:perturbation_tag, :reason]
  defstruct [:perturbation_tag, :reason]

  @type t :: %__MODULE__{perturbation_tag: atom(), reason: atom()}

  @impl true
  def tag, do: :default_passed
end
