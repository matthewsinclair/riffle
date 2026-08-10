defmodule Riffle.Ctx do
  @moduledoc """
  THE run context: a typed composite root, threaded immutably through the knot.

  Every slot carries a declared type and is read by dot access, so a field typo
  fails at the call site rather than returning `nil` from a bag. Exactly one slot
  is a free-form overlay -- `metadata` -- and it is declared as such in
  `overlay_slots/0`, which the composite-root fence checks against the typespec.
  A slot that quietly became a map would fail the build.

  This module exposes construction, one overlay read, and one derived predicate.
  The typed slots are read by dot -- `ctx.input`, `ctx.status` -- so there are no
  pass-through accessors, which is where the seventy-six-function surface this
  replaces began. There are no setters either: the one way to change a context
  is to apply a perturbation through `Riffle.Ctx.Knot`, which makes the state
  transition a single auditable point.

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
    # validate! rather than fetch-what-we-know: a typo in an option name would
    # otherwise be discarded in silence, which is the bag behaviour this module
    # exists to refuse -- and the refusal has to reach the constructor too.
    validated = Keyword.validate!(opts, [:run_id, metadata: %{}])

    %__MODULE__{
      run_id: Keyword.fetch!(validated, :run_id),
      metadata: validated |> Keyword.fetch!(:metadata) |> Map.new()
    }
  end

  @doc """
  Reads a key from the metadata overlay.

  Keyed access is what an overlay is for; the typed slots are reached by dot.

  Tagged rather than bare, and for a concrete reason: a recorded metadata value
  may itself be `nil`, so a bare read cannot distinguish "absent" from "present
  and nil". This is the same shape the catalogs' `fetch_by_tag/1` uses.
  """
  @spec fetch_metadata(t(), atom()) :: {:ok, term()} | :error
  def fetch_metadata(%__MODULE__{metadata: metadata}, key) when is_atom(key),
    do: Map.fetch(metadata, key)

  @doc "Whether the run has accumulated any error."
  @spec has_errors?(t()) :: boolean()
  def has_errors?(%__MODULE__{errors: errors}), do: errors != []
end
