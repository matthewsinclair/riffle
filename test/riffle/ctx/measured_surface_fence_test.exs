defmodule Riffle.Ctx.MeasuredSurfaceFenceTest do
  use ExUnit.Case, async: true

  alias Riffle.Ctx
  alias Riffle.Ctx.Emission
  alias Riffle.Ctx.Perturbation
  alias Riffle.WaistHelpers

  # AC-03.1. The waist's minimum surface was measured, not guessed: the context
  # functions the extricated code actually consumed, by call-site count, in
  # intent/docs/extrication-handoff.md. This fence holds the mapping to account.
  #
  # A capability maps to catalog tags, to a state read, or to a recorded drop.
  # The fence checks every mapping resolves to something live, so a capability
  # cannot be claimed as covered by a type or a function that does not exist,
  # and it checks the reverse -- every catalog type traces back to a measured
  # capability or is declared as deliberately beyond it. Coverage by enumeration
  # in both directions; the design.md prose is the argument, this is the proof.

  @measured [
    {:t, {:type, :t}},
    {:with_status, {:tags, [:run_started, :run_failed, :status_changed]}},
    {:set_metadata_value, {:tags, [:metadata_recorded, :metadata_set]}},
    {:new, {:read, {:new, 1}}},
    {:debug, {:tags, [:diagnostic_reported, :diagnostic]}},
    {:event_completed, {:tags, [:stage_exited, :stage_completed]}},
    {:add_error, {:tags, [:error_reported, :error_raised]}},
    {:set_input, {:tags, [:input_received, :input_set]}},
    {:with_inputs, {:tags, [:input_received, :input_set]}},
    {:set_cargo_item,
     {:dropped, "an untyped scratch bag; a stage's product leaves as an emission"}},
    {:event_started, {:tags, [:stage_entered, :stage_started]}},
    {:log, {:tags, [:diagnostic_reported, :diagnostic]}},
    {:set_output, {:tags, [:run_completed, :output_produced]}},
    {:get_input, {:slot, :input}},
    {:record_event,
     {:dropped,
      "events are emissions and they leave; recording them into state is the shape replaced"}},
    {:has_errors?, {:read, {:has_errors?, 1}}},
    {:get_output, {:slot, :output}},
    {:complete, {:tags, [:run_completed, :status_changed]}},
    {:event_progress, {:tags, [:stage_progressed, :stage_progress]}},
    {:verbose?,
     {:dropped, "the core never branches on who is listening; verbosity is a consumer's concern"}},
    {:set_opt, {:read, {:new, 1}}},
    {:get_metadata, {:read, {:fetch_metadata, 2}}},
    {:get_cargo_item, {:dropped, "dropped with set_cargo_item"}},
    {:get_all_stats,
     {:dropped, "derivable from the emission stream by a consumer; counters here invite mutation"}}
  ]

  # Types that exist for reasons other than serving a measured capability.
  @beyond_measured [:default_passed]

  test "fence: every measured capability maps to a live expression or a declared drop" do
    assert length(@measured) == 24

    assert unresolved_tags() == []
    assert unresolved_reads() == []
    assert unresolved_slots() == []
    assert unreasoned_drops() == []
  end

  test "fence: the composite root declares the type the surface is measured against" do
    assert {:type, {:t, _definition, []}} = WaistHelpers.fetch_type!(Ctx, :t)
  end

  test "fence: every catalog type traces back to a measured capability or a declared exception" do
    # No non-vacuity guard here: both catalogs build their tag map from a closed
    # literal list, so the type checker proves this list non-empty and rejects
    # the guard as provably true. `mix gate` compiles tests with
    # --warnings-as-errors, so that proof fails the build rather than a test --
    # which is the stronger form of the same protection.
    declared = Perturbation.tags() ++ Emission.tags()

    claimed =
      for {_capability, {:tags, tags}} <- @measured, tag <- tags, into: MapSet.new(), do: tag

    orphans = Enum.reject(declared, &(&1 in claimed or &1 in @beyond_measured))

    assert orphans == []
  end

  defp unresolved_tags do
    known = MapSet.new(Perturbation.tags() ++ Emission.tags())

    for {capability, {:tags, tags}} <- @measured,
        tag <- tags,
        tag not in known,
        do: {capability, tag}
  end

  defp unresolved_reads do
    for {capability, {:read, {function, arity}}} <- @measured,
        not WaistHelpers.exports?(Ctx, function, arity),
        do: {capability, function, arity}
  end

  defp unresolved_slots do
    slots = Map.keys(WaistHelpers.field_types!(Ctx))

    for {capability, {:slot, slot}} <- @measured, slot not in slots, do: {capability, slot}
  end

  defp unreasoned_drops do
    for {capability, {:dropped, reason}} <- @measured, String.trim(reason) == "", do: capability
  end
end
