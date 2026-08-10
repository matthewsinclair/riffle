---
verblock: "10 Aug 2026:v0.2: cc - Ratified contract authored (hv ruling 2026-08-10)"
st_id: ST0002
title: "ctx-next: the Bowtie waist -- acceptance contract"
---

# ST0002 ctx-next: the Bowtie waist -- Acceptance

> Canonical acceptance contract for ST0002. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them. Real test code lives in the suite (paths cited below); this file is the contract plus the AC-to-AT coverage map plus live status. info.md / WP info.md reference this file and never restate ACs (one home).
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Change control: clarifying an AC or AT is verifier-and-builder; shrinking scope, or weakening an AT to make it pass, needs the owner.
>
> AT status vocabulary: to-write (red-first) | red | green | n/a (non-test: doc / eyeball / gate).
>
> Non-test ACs carry their state inline -- `-- evidence: <ref> -- satisfied: yes|no` on the AC line; test-backed ACs are satisfied by a green covering AT (computed, never written). Multi-AC coverage on an AT is comma-separated.
>
> Ratified by hv 2026-08-10. Two rulings shape this contract. First: Riffle is an example of the Bowtie pattern, not its reference implementation -- the pattern is a conceptual shape Riffle follows, and no AC exists to demonstrate generality. Second: the discipline learned on Lamplight applies in full -- the ATs below are conformance fences (whole-class invariants enumerated exhaustively) rather than example tests, because a fence catches the drift class a hand-written test misses.

## Acceptance Criteria

### ST-level

None -- WP-distributed.

### WP-01 -- Ctx and the typed catalogs (status: WIP)

- AC-01.1 `Riffle.Ctx` is a typed composite root, not a bag: every slot carries a declared type, exactly one slot is a declared free-form overlay (`metadata`), and no slot accumulates perturbations or emissions
- AC-01.2 Both catalogs are closed registries: every type declares a tag and a typespec, the parent enumerates its implementations in a closed list built at compile time, and an unknown tag loud-fails rather than falling through
- AC-01.3 Catalog bijection holds: the struct modules present under each catalog namespace are exactly the registry's declared implementations, and tags are unique within each catalog
- AC-01.4 The waist names no engine module: zero references to `Riffle.Predicate` anywhere under `lib/riffle/ctx/` -- emission payloads stay opaque to the waist (handoff stitch 2 must not re-form)
- AC-01.5 The engine names no waist module: zero references to `Riffle.Ctx` anywhere under `lib/riffle/predicate/` -- the dependency inversion holds in both directions, so the two compose only at an edge
- AC-01.6 (non-test) The capability map is authored: each of the 24 measured Ctx functions maps to a perturbation, an emission, or a state read, or is dropped with a recorded reason -- evidence: design.md "Capability map" section (20 expressed, 4 dropped with reasons: cargo pair, record_event, verbose?, Stats.get_all_stats) -- satisfied: yes

### WP-02 -- The pure knot (status: Not Started)

- AC-02.1 The knot is unconditionally pure: no module reachable from it references a clock, a random source, a process, a table, a file, or a logger. Approximate purity is a failure, not a tolerance
- AC-02.2 The knot is deterministic: the same (ctx, perturbation) yields identical `{ctx', emissions}` on every application
- AC-02.3 Delivery is total: every perturbation type in the catalog yields at least one emission, an unhandled perturbation surfaces a typed default-pass through one funnel, and there is no allowlist of exempt types
- AC-02.4 The knot emits the full typed stream unconditionally -- it takes no consumer, mask, or filter argument, and never branches its generation on who is listening
- AC-02.5 Replay holds: a recorded perturbation sequence applied to the same initial Ctx reproduces an identical trajectory of `{ctx', emissions}` pairs

### WP-03 -- Coverage, bedrock, and close (status: Not Started)

- AC-03.1 The measured surface is covered by enumeration, not assertion: every capability in the map is checked against the live catalogs and state reads, and a declared drop must carry its reason
- AC-03.2 (non-test) `intent/docs/bedrock.md` records the commitments this thread fixes, the negations that matter, and the rule that a contradiction with it is a bug in the contradicting document -- evidence: the file, ratified by hv -- satisfied: no
- AC-03.3 (non-test) Module registry and as-built design recorded -- evidence: MODULES.md rows for every new module; design.md approach + decisions + capability map -- satisfied: no
- AC-03.4 (non-test) Rule-library conformance at ST0001's bar -- evidence: critic-elixir review + test-check on the new tree, zero CRITICAL and zero Highlander/PFIC WARNING -- satisfied: no
- AC-03.5 (non-test) `mix gate` green (format, compile and test under warnings-as-errors, `credo --strict`) -- evidence: gate run cited in impl.md -- satisfied: no
- AC-03.6 (non-test) The inherited "reference implementation" claim is struck from ST0002 info.md and `intent/docs/extrication-handoff.md` (hv ruling 2026-08-10) so it stops steering later sessions -- evidence: both files -- satisfied: no

## Acceptance Tests

### WP-01

- AT-01.1 test/riffle/ctx/ctx_test.exs::"invariant: the composite root is typed, with one declared overlay and no event accumulation" -- covers AC-01.1 -- status: green
- AT-01.2 test/riffle/ctx/catalog_fence_test.exs::"invariant: an unknown tag loud-fails at both catalogs" -- covers AC-01.2 -- status: green
- AT-01.3 test/riffle/ctx/catalog_fence_test.exs::"fence: struct modules on disk are exactly the declared implementations, tags unique" -- covers AC-01.3 -- status: green
- AT-01.4 test/riffle/ctx/boundary_fence_test.exs::"fence: the waist names no engine module" -- covers AC-01.4 -- status: green
- AT-01.5 test/riffle/ctx/boundary_fence_test.exs::"fence: the engine names no waist module" -- covers AC-01.5 -- status: green
- Coverage: AC-01.1..5 covered above; AC-01.6 is non-test with evidence inline.

### WP-02

- AT-02.1 test/riffle/ctx/purity_fence_test.exs::"fence: no module reachable from the knot touches a clock, random, process, table, file, or logger" -- covers AC-02.1 -- status: to-write (red-first)
- AT-02.2 test/riffle/ctx/knot_test.exs::"invariant: the same perturbation against the same ctx yields identical results" -- covers AC-02.2 -- status: to-write (red-first)
- AT-02.3 test/riffle/ctx/delivery_floor_fence_test.exs::"fence: every catalog perturbation yields at least one emission" -- covers AC-02.3 -- status: to-write (red-first)
- AT-02.4 test/riffle/ctx/knot_test.exs::"invariant: the knot emits the full stream and takes no consumer argument" -- covers AC-02.4 -- status: to-write (red-first)
- AT-02.5 test/riffle/ctx/knot_test.exs::"invariant: a recorded perturbation sequence replays to an identical trajectory" -- covers AC-02.5 -- status: to-write (red-first)
- Coverage: complete -- AC-02.1..5 each covered by an AT above.

### WP-03

- AT-03.1 test/riffle/ctx/measured_surface_fence_test.exs::"fence: every measured capability maps to a live expression or a declared drop" -- covers AC-03.1 -- status: to-write (red-first)
- Coverage: AC-03.1 covered above; AC-03.2..6 are non-test with evidence inline.
