defmodule Riffle.Service.Result do
  @moduledoc """
  The typed outcome of a service run.

  A run produces three things a caller wants and one it usually does not. The
  three: how many rows went in, how many survived, and what each stage did. The
  fourth is the run context and its emission stream, carried here because a
  caller that wants the full evidence should not have to run again to get it.

  `stages` is the summary, and it is deliberately a keyword list rather than a
  map. Two loops in one pipeline may share a name -- nothing forbids it -- and a
  map would silently merge them into one entry, which is exactly the class of
  quiet loss this project exists to refuse. It arrives in the order the loops
  ran, because that is the order the evidence was emitted in.
  """

  alias Riffle.Ctx
  alias Riffle.Ctx.Emission

  @type t :: %__MODULE__{
          pipeline: atom(),
          input_count: non_neg_integer(),
          output_count: non_neg_integer(),
          stages: [{atom(), non_neg_integer()}],
          ctx: Ctx.t(),
          emissions: [Emission.t()]
        }

  @enforce_keys [:pipeline, :input_count, :output_count, :stages, :ctx, :emissions]
  defstruct [:pipeline, :input_count, :output_count, :stages, :ctx, :emissions]
end
