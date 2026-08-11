defmodule Riffle.Ctx.Emission.MetadataSet do
  @moduledoc """
  A derived fact was recorded about the run.

  `key` names the fact and `value` is it.

  Yielded by `Riffle.Ctx.Perturbation.MetadataRecorded`. Because the pair
  travels in the emission stream as well as landing in the context overlay, a
  recorded fact can be checked against the emissions it was derived from
  without trusting the context -- which is what bedrock commitment 8, no
  derived claim outlives its evidence, is enforced against.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:key, :value]
  defstruct [:key, :value]

  @type t :: %__MODULE__{key: atom(), value: term()}

  @impl true
  def tag, do: :metadata_set
end
