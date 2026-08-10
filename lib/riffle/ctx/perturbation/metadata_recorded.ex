defmodule Riffle.Ctx.Perturbation.MetadataRecorded do
  @moduledoc """
  A source has recorded a metadata value against the run.
  """

  @behaviour Riffle.Ctx.Catalog

  @enforce_keys [:key, :value]
  defstruct [:key, :value]

  @type t :: %__MODULE__{key: atom(), value: term()}

  @impl true
  def tag, do: :metadata_recorded
end
