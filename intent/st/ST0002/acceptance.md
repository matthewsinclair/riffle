---
st_id: ST0002
title: ctx-next: the Bowtie waist
---

# ST0002: ctx-next: the Bowtie waist -- Acceptance

> **THIS FILE IS A GENERATED VIEW, AND A ROW AUTHORED HERE IS DISCARDED BY THE NEXT SYNC.** The acceptance contract is canon in the thread model; this file renders it. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them.
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Test-backed satisfaction is COMPUTED from covering green ATs and never stored -- storing it would be double truth. An AC has four states, not two: beyond satisfied and unsatisfied, a requirement can be **descoped** to a named thread or **withdrawn** with its reason on the record. Both are non-blocking and both are reported separately, so a thread that descoped half its contract looks like one.

## Acceptance Criteria

### WP-01 -- Ctx and the typed catalogs (status: Done)

- AC-01.1 `Riffle.Ctx` is a typed composite root, not a bag: every slot carries a declared type, exactly one slot is a declared free-form overlay (`metadata`), and no slot accumulates perturbations or emissions -- satisfied: yes (computed)
- AC-01.2 Both catalogs are closed registries: every type declares a tag and a typespec, the parent enumerates its implementations in a closed list built at compile time, and an unknown tag loud-fails rather than falling through -- satisfied: yes (computed)
- AC-01.3 Catalog bijection holds: the struct modules present under each catalog namespace are exactly the registry's declared implementations, and tags are unique within each catalog -- satisfied: yes (computed)
- AC-01.4 The waist names no engine module: zero references to `Riffle.Predicate` anywhere under `lib/riffle/ctx/` -- emission payloads stay opaque to the waist (handoff stitch 2 must not re-form) -- satisfied: yes (computed)
- AC-01.5 The engine names no waist module: zero references to `Riffle.Ctx` anywhere under `lib/riffle/predicate/` -- the dependency inversion holds in both directions, so the two compose only at an edge -- satisfied: yes (computed)
- AC-01.6 (non-test) The capability map is authored: each of the 24 measured Ctx functions maps to a perturbation, an emission, or a state read, or is dropped with a recorded reason -- evidence: design.md "Capability map" section (20 expressed, 4 dropped with reasons: cargo pair, record_event, verbose?, Stats.get_all_stats) -- satisfied: yes

### WP-02 -- The pure knot (status: Done)

- AC-02.1 The knot is unconditionally pure: no module reachable from it references a clock, a random source, a process, a table, a file, or a logger. Approximate purity is a failure, not a tolerance -- satisfied: yes (computed)
- AC-02.2 The knot is deterministic: the same (ctx, perturbation) yields identical `{ctx', emissions}` on every application -- satisfied: yes (computed)
- AC-02.3 Delivery is total: every perturbation type in the catalog yields at least one emission, an unhandled perturbation surfaces a typed default-pass through one funnel, and there is no allowlist of exempt types -- satisfied: yes (computed)
- AC-02.4 The knot emits the full typed stream unconditionally -- it takes no consumer, mask, or filter argument, and never branches its generation on who is listening -- satisfied: yes (computed)
- AC-02.5 Replay holds: a recorded perturbation sequence applied to the same initial Ctx reproduces an identical trajectory of `{ctx', emissions}` pairs -- satisfied: yes (computed)

### WP-03 -- Coverage, bedrock, and close (status: Done)

- AC-03.1 The measured surface is covered by enumeration, not assertion: every capability in the map is checked against the live catalogs and state reads, and a declared drop must carry its reason -- satisfied: yes (computed)
- AC-03.2 (non-test) `intent/docs/bedrock.md` records the commitments this thread fixes, the negations that matter, and the rule that a contradiction with it is a bug in the contradicting document -- evidence: `intent/docs/bedrock.md` (7 commitments, 5 negations, the fence table binding each commitment to its enforcement) -- satisfied: yes
- AC-03.3 (non-test) Module registry and as-built design recorded -- evidence: MODULES.md "ctx-next (the waist)" section (6 rows incl. Catalog and the test-support helper); design.md DD-1..DD-7 + capability map; impl.md as-built -- satisfied: yes
- AC-03.4 (non-test) Rule-library conformance at ST0001's bar -- evidence: two critic rounds (round 1: 1C/4W code, 6C test; round 2: 0C/3W code, 2C/3W test); every CRITICAL and every Highlander WARNING fixed at source, none suppressed -- satisfied: yes
- AC-03.5 (non-test) `mix gate` green (format, compile and test under warnings-as-errors, `credo --strict`) -- evidence: 318 passed (67 doctests, 251 tests), 556 mods/funs, zero credo findings -- satisfied: yes
- AC-03.6 (non-test) The inherited "reference implementation" claim is struck from ST0002 info.md and `intent/docs/extrication-handoff.md` (hv ruling 2026-08-10) so it stops steering later sessions -- evidence: info.md Context rewritten; handoff carries a dated correction note rather than a silent deletion -- satisfied: yes

## Acceptance Tests

### WP-01 -- Ctx and the typed catalogs (status: Done)

- AT-01.1 (legacy) test/riffle/ctx/ctx_test.exs (3 invariants: the declared overlay is exactly metadata, every other slot carries a concrete type, no slot accumulates catalog types -- covers AC-01.1 -- status: green
- AT-01.2 (legacy) test/riffle/ctx/catalog_fence_test.exs::"invariant: an unknown tag loud-fails at both catalogs" -- covers AC-01.2 -- status: green
- AT-01.3 (legacy) test/riffle/ctx/catalog_fence_test.exs (4 fences: per-catalog module/registry bijection, and per-catalog union-type/membership agreement) -- covers AC-01.3 -- status: green
- AT-01.4 (legacy) test/riffle/boundary_fence_test.exs::"fence: the waist names no engine module" (AST-based; carries a brace-alias positive control) -- covers AC-01.4 -- status: green
- AT-01.5 (legacy) test/riffle/boundary_fence_test.exs::"fence: the engine names no waist module" -- covers AC-01.5 -- status: green

### WP-02 -- The pure knot (status: Done)

- AT-02.1 (legacy) test/riffle/ctx/purity_fence_test.exs (2 fences: the forbidden-call closure, and the closure staying inside the waist) -- covers AC-02.1 -- status: green
- AT-02.2 (legacy) test/riffle/ctx/knot_test.exs::"invariant: the same perturbation against the same ctx yields the same pinned result" -- covers AC-02.2 -- status: green
- AT-02.3 (legacy) test/riffle/ctx/delivery_floor_fence_test.exs::"fence: every catalog perturbation yields a real emission, never the floor" -- covers AC-02.3 -- status: green
- AT-02.4 (legacy) test/riffle/ctx/knot_test.exs::"invariant: the knot emits the full stream and takes no consumer argument" -- covers AC-02.4 -- status: green
- AT-02.5 (legacy) test/riffle/ctx/knot_test.exs::"invariant: a recorded perturbation sequence replays to the pinned trajectory" -- covers AC-02.5 -- status: green

### WP-03 -- Coverage, bedrock, and close (status: Done)

- AT-03.1 (legacy) test/riffle/ctx/measured_surface_fence_test.exs (3 fences: every capability resolves to a live tag, read, slot or reasoned drop; the composite root declares t(); every catalog type traces back to a capability or a declared exception) -- covers AC-03.1 -- status: green

---

_Generated by Intent v3.0.0-dev from `thread.json`. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
