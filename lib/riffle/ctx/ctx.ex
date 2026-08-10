defmodule Riffle.Ctx do
  @moduledoc """
  THE run context: a typed composite root, threaded immutably through the knot.

  Every slot carries a declared type and is read by dot access, so a field typo
  fails at the call site rather than returning `nil` from a bag. Exactly one slot
  is a free-form overlay -- `metadata` -- and it is declared as such in
  `overlay_slots/0`, which the composite-root fence checks against the typespec.
  A slot that quietly became a map would fail the build.

  This module exposes reads and construction only. There are no setters: the one
  way to change a context is to apply a perturbation through `Riffle.Ctx.Knot`,
  which is what makes the state transition a single auditable point rather than
  seventy-six accessors any caller can reach for.

  `new/1` takes the run id rather than generating one. Generating an identifier
  would mean randomness, and randomness inside the waist would end the purity
  the whole design rests on -- non-determinism enters as data or not at all.
  """

  @overlay_slots [:metadata]

  @enforce_keys [:run_id]
  defstruct [:run_id, status: :pending, input: nil, output: nil, errors: [], metadata: %{}]

  @type status :: :pending | :running | :completed | :failed

  @type t :: %__MODULE__{
          run_id: String.t(),
          status: status(),
          input: term(),
          output: term(),
          errors: [term()],
          metadata: %{optional(atom()) => term()}
        }

  @doc """
  The slots declared as free-form overlays.

  Everything not listed here must carry a concrete type. The fence in
  `test/riffle/ctx/ctx_test.exs` reads the `t()` typespec and asserts the map-typed
  slots are exactly this list, so an undeclared bag cannot appear.
  """
  @spec overlay_slots() :: [atom()]
  def overlay_slots, do: @overlay_slots

  @doc """
  Builds a context for a run.

  The run id is required: the waist does not mint identifiers, because that would
  be non-determinism generated inside a pure core.
  """
  @spec new(keyword()) :: t()
  def new(opts) when is_list(opts) do
    %__MODULE__{
      run_id: Keyword.fetch!(opts, :run_id),
      metadata: opts |> Keyword.get(:metadata, %{}) |> Map.new()
    }
  end

  @doc "The run's input, as supplied. Opaque to the waist."
  @spec get_input(t()) :: term()
  def get_input(%__MODULE__{input: input}), do: input

  @doc "The run's output, as produced. Opaque to the waist."
  @spec get_output(t()) :: term()
  def get_output(%__MODULE__{output: output}), do: output

  @doc """
  Reads a key from the metadata overlay.

  Keyed access is what an overlay is for; the typed slots are reached by dot.
  """
  @spec get_metadata(t(), atom()) :: term()
  def get_metadata(%__MODULE__{metadata: metadata}, key) when is_atom(key),
    do: Map.get(metadata, key)

  @doc "Whether the run has accumulated any error."
  @spec has_errors?(t()) :: boolean()
  def has_errors?(%__MODULE__{errors: errors}), do: errors != []
end
