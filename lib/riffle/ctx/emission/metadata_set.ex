defmodule Riffle.Ctx.Emission.MetadataSet do
  @moduledoc """
  A metadata key was set on the run.
  """

  @behaviour Riffle.Ctx.Emission.Kind

  @enforce_keys [:key, :value]
  defstruct [:key, :value]

  @type t :: %__MODULE__{key: atom(), value: term()}

  @impl true
  def tag, do: :metadata_set
end
