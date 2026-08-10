---
verblock: "10 Aug 2026:v0.2: cc - Contract authored against the D2 root cause and bedrock"
st_id: ST0003
title: "SIA pattern layer rewrite -- acceptance contract"
---

# ST0003 SIA pattern layer rewrite -- Acceptance

> Canonical acceptance contract for ST0003. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them. Real test code lives in the suite (paths cited below); this file is the contract plus the AC-to-AT coverage map plus live status. info.md / WP info.md reference this file and never restate ACs (one home).
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Change control: clarifying an AC or AT is verifier-and-builder; shrinking scope, or weakening an AT to make it pass, needs the owner.
>
> AT status vocabulary: to-write (red-first) | red | green | n/a (non-test: doc / eyeball / gate).
>
> Non-test ACs carry their state inline -- `-- evidence: <ref> -- satisfied: yes|no` on the AC line; test-backed ACs are satisfied by a green covering AT (computed, never written). Multi-AC coverage on an AT is comma-separated.
>
> What this contract is shaped by. Three things, all settled before it was written. **The D2 root cause** (ST0001 verdict): the source layer computed correct results, discarded them, and recorded `results_available: true` -- a flag that lied, next to statistics whose evidence had been thrown away. Most of WP-01 exists to make that class of defect impossible rather than absent. **Bedrock commitment 6**: the engine is a rules engine, which is inference, which lives at an edge -- so the pattern layer is the edge that joins engine and waist, and neither of those may name it. **hv's ratified scope calls**: `.pred` file pipelines are in; the CSV datasource is out, replaced by plain ingest.

## Acceptance Criteria

### ST-level

- AC-00.1 (non-test) `mix gate` green at close -- format, compile and test both under warnings-as-errors, `credo --strict` -- evidence: impl.md gate record -- satisfied: no
- AC-00.2 (non-test) Every fence this thread adds is mutation-checked: break the thing it guards, watch it go red, restore. A fence that cannot fail is not a fence -- evidence: impl.md mutation table -- satisfied: no
- AC-00.3 (non-test) Every module created is registered in `intent/llm/MODULES.md` before its file exists -- evidence: MODULES.md "SIA (the pattern layer)" section -- satisfied: no

### WP-01 -- The staged edge (status: WIP)

- AC-01.1 A run stages its pipeline loop-by-loop through the knot: `RunStarted` and `InputReceived` bracket the front, each loop contributes `StageEntered` then `StageProgressed` then `StageExited` in that order, and `RunCompleted` closes it. The stage's identity is the loop's own name -- no mapping table, no naming convention parsed out of tags
- AC-01.2 A completed run's results are the same value in three places: the final stage's `StageCompleted` output, the `OutputProduced` emission payload, and `ctx.output`. No path exists by which a run reports completion while its results are absent
- AC-01.3 Every fact the run derives arrives with its evidence: each `StageProgress` count equals the length of that stage's `StageCompleted` output, and every `MetadataSet` the run emits carries a declared key whose value recomputes exactly from the stage emissions in the same stream. A count cannot be recorded without the collection it counts
- AC-01.4 The knot is the only transition: no `Riffle.Ctx` struct-update expression exists anywhere in `lib/` outside the waist, and the pattern layer contains no map-update expression of any kind. It changes run state by applying a perturbation or not at all. (Clarified before building, 2026-08-10: the first draft said "no `%Riffle.Ctx{... | ...}` anywhere in lib/", which fences only the explicit form -- the knot itself reaches its slots through bare `%{ctx | ...}`, and so would anything reaching in. The two-clause form above is what is actually provable, and it is stricter inside the layer)
- AC-01.5 The pattern layer swallows nothing: it contains no `rescue`, `catch` or `after`, and an exception raised inside predicate evaluation propagates out of the run unchanged, with its type and message intact
- AC-01.6 The engine names no pattern-layer module, at any depth -- the source layer's hardcoded fallback to its own default-pipeline module was the one stitch inside ported code, and it must not re-form
- AC-01.7 The waist names no pattern-layer module -- the core does not know who is listening
- AC-01.8 Ingest is total over its declared input and loud outside it: an enumerable of field maps or `Item` structs is accepted, and anything else raises naming what arrived

### WP-02 -- Pipeline sources and the characterisation contract (status: WIP)

- AC-02.1 A pipeline resolves from a closed source vocabulary -- a `Pipeline` struct, `{:module, module}`, `{:file, path}`, or `:default_module` -- and a source outside it is a loud failure, never a silent empty run
- AC-02.2 The five archived characterisation assertions, every one pinned at `assert [] = results`, are green in Riffle in their strengthened form: each asserts the concrete surviving items and the concrete tags those items carry, not a shape
- AC-02.3 The four archived tests that asserted nothing -- missing file, missing pipeline name from a module, missing name from a file, empty input -- each assert a concrete outcome here
- AC-02.4 An unresolvable source fails the run as a typed signal: status `:failed`, the reason in `ctx.errors`, an `ErrorRaised` emission carrying it, and no results claimed anywhere in the stream
- AC-02.5 (non-test) Riffle ships its own sense/infer/act pipeline definition in both source forms -- evidence: priv/sia/sia.pred and lib/riffle/sia/default_pipeline.ex -- same definitions in both source forms, held identical by sources_test with the cache off -- satisfied: yes
- AC-02.6 The file source and the module source agree: the same definitions over the same input produce identical results, item for item and tag for tag

### WP-03 -- Record and close (status: WIP)

- AC-03.1 (non-test) design.md records the decisions with their rationale, including what was deliberately not built -- evidence: intent/st/ST0003/design.md -- satisfied: no
- AC-03.2 (non-test) impl.md records the as-built, the critic rounds and their outcomes, and the mutation table -- evidence: intent/st/ST0003/impl.md -- satisfied: no
- AC-03.3 (non-test) Rule-library conformance at ST0001/ST0002's bar: `critic-elixir` review and test-check over every file this thread touched, every CRITICAL and every Highlander WARNING fixed at source, none suppressed -- evidence: impl.md critic section -- satisfied: no
- AC-03.4 (non-test) Zero source-project traces in the new files -- evidence: `extrication_gate_test` green -- satisfied: no
- AC-03.5 (non-test) `intent/docs/bedrock.md` reflects the pattern layer: the commitments it adds, or the recorded finding that none changed -- evidence: intent/docs/bedrock.md -- satisfied: no

## Acceptance Tests

### WP-01

- AT-01.1 test/riffle/sia/sia_test.exs::"invariant: a run stages every loop through the knot, in order" -- covers AC-01.1 -- status: green
- AT-01.2 test/riffle/sia/evidence_fence_test.exs::"fence: a completed run's results are the same value in all three places" -- covers AC-01.2 -- status: green
- AT-01.3 test/riffle/sia/evidence_fence_test.exs::"fence: every derived fact arrives with its evidence" -- covers AC-01.3 -- status: green
- AT-01.4 test/riffle/single_transition_fence_test.exs (3: no Ctx struct-update outside the waist, no map update at all in the layer, and a control proving the walk sees both update spellings and neither construction nor match) -- covers AC-01.4 -- status: green
- AT-01.5 test/riffle/sia/no_rescue_fence_test.exs (2: the AST fence over the layer, and a raising predicate propagating out of a run) -- covers AC-01.5 -- status: green
- AT-01.6 test/riffle/boundary_fence_test.exs::"fence: the engine names no pattern-layer module" -- covers AC-01.6 -- status: green
- AT-01.7 test/riffle/boundary_fence_test.exs::"fence: the waist names no pattern-layer module" -- covers AC-01.7 -- status: green
- AT-01.8 test/riffle/sia/sia_test.exs (2: field maps and Item structs both ingest; anything else raises naming what arrived) -- covers AC-01.8 -- status: green
- Coverage: complete -- AC-01.1..8 each covered by an AT above.

### WP-02

- AT-02.1 test/riffle/sia/sources_test.exs::"invariant: the source vocabulary is closed and an unknown source raises" -- covers AC-02.1 -- status: green
- AT-02.2 test/riffle/sia/characterisation_test.exs (5: main and sense from a module, main, sense and infer from a file -- each pinning the surviving items and their tags) -- covers AC-02.2 -- status: green
- AT-02.3 test/riffle/sia/characterisation_test.exs (4: the tests that asserted nothing, each now asserting a concrete outcome) -- covers AC-02.3, AC-02.4 -- status: green
- AT-02.4 test/riffle/sia/sources_test.exs::"invariant: the file source and the module source produce identical results" -- covers AC-02.6 -- status: green
- Coverage: AC-02.1..4 and AC-02.6 covered above; AC-02.5 is non-test with evidence inline.

### WP-03

- Coverage: none -- AC-03.1..5 are all non-test, with evidence inline.
