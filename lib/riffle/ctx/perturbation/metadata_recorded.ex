defmodule Riffle.Ctx.Perturbation.MetadataRecorded do
  @moduledoc """
  A source records a derived fact about the run.

  `key` names the fact and `value` is it.

  Through the knot it writes the pair into the context's metadata overlay and
  yields a `Riffle.Ctx.Emission.MetadataSet` carrying both.

  The overlay is for facts derived from the run, and the discipline that goes
  with it is bedrock commitment 8: no derived claim outlives its evidence. A
  value recorded here should be recomputable from the emissions of the same
  run -- `Riffle.Sia` records one key, `:stage_counts`, and it is a projection
  of the stage emissions rather than a tally kept beside them.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:key, :value]
  defstruct [:key, :value]

  @type t :: %__MODULE__{key: atom(), value: term()}

  @impl true
  def tag, do: :metadata_recorded
end
