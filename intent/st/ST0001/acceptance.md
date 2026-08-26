---
st_id: ST0001
title: Extricate Predicate and SIA from Multiplyer
---

# ST0001: Extricate Predicate and SIA from Multiplyer -- Acceptance

> **THIS FILE IS A GENERATED VIEW, AND A ROW AUTHORED HERE IS DISCARDED BY THE NEXT SYNC.** The acceptance contract is canon in the thread model; this file renders it. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them.
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Test-backed satisfaction is COMPUTED from covering green ATs and never stored -- storing it would be double truth. An AC has four states, not two: beyond satisfied and unsatisfied, a requirement can be **descoped** to a named thread or **withdrawn** with its reason on the record. Both are non-blocking and both are reported separately, so a thread that descoped half its contract looks like one.

## Acceptance Criteria

### WP-01 -- D2 root-cause and verdict (status: Done)

- AC-01.1 (non-test) D2 root-caused with the engine-vs-glue verdict recorded, file:line evidence from real reads of the archive -- evidence: design.md "D2 verdict" section -- satisfied: yes

### WP-02 -- Scaffolding and CI gate (status: Done)

- AC-02.1 (non-test) CI runs format check + compile + test with warnings-as-errors covering test compilation, green on the skeleton before the port lands -- evidence: .github/workflows/ci.yml runs `mix gate` (the single local/CI gate alias in mix.exs); local `mix gate` green on skeleton 2026-08-10 (upstream Actions run lands on next hv push) -- satisfied: yes

### WP-03 -- Predicate engine port (status: Done)

- AC-03.1 The ported engine and its full ported test suite are green under `mix test --warnings-as-errors` (D5 class structurally excluded) -- satisfied: yes (computed)
- AC-03.2 Zero source-project traces in `lib/` and `test/` -- modules, atoms, app-env keys, strings, comments, moduledocs (hv ruling 2026-08-10) -- satisfied: yes (computed)
- AC-03.3 Default-pipeline resolution is config-injected (`:riffle, :default_pipeline`); unset config surfaces an explicit error; the engine names no pattern-layer module -- satisfied: yes (computed)
- AC-03.4 (non-test) Ported code and tests remediated against the rule library -- critic-elixir run on the ported tree with CRITICAL/HIGH findings fixed (hv rewrite-flexibility ruling 2026-08-10; DD-4 as amended) -- evidence: critic reports (11 CRITICAL: 5 lib + 6 test, all fixed in commits 29eac91, 335a655, bea85fa; structural WARNINGs dispositioned to WP-04 per DD-7) -- satisfied: yes

### WP-04 -- PFIC transform and hydration consolidation (status: Done)

- AC-04.1 One hydration/resolution path: pipeline.ex, loop.ex, registry.ex, loader.ex, and macro-generated functions resolve references through a single loud resolver; no residual ad-hoc resolution -- satisfied: yes (computed)
- AC-04.2 (non-test) Engine conditional shapes conform to PFIC; critic-elixir re-run on lib/riffle/ reports zero CRITICAL and zero Highlander/PFIC WARNINGs -- evidence: full-tree re-run post-c10 (0 CRITICAL, 6 WARNING -> 5 fixed in R4a d8cac87, 1 in R4b 7c3c940) + targeted R4b re-review of the four DSL files (0 CRITICAL, 0 WARNING; Highlander/PFIC verified structurally: block ladders exist only in Dsl.Statements); test-check re-run 0 CRITICAL at R4a, and its post-R4b CRITICAL (the STD test proving nothing) exposed-and-fixed at 7c3c940 -- satisfied: yes
- AC-04.3 Loop single-item and stream paths share one evaluation entry point, cache honoured on both -- satisfied: yes (computed)
- AC-04.4 (non-test) expr-macro test family consolidated to one canonical file + shared support helper; scratch files deleted; suite green -- evidence: c9 (c0d80fa): five scratch files deleted, `test/riffle/predicate/dsl/expr_test.exs` canonical with ONE shared in-file DSL fixture module (support-helper judgement recorded in impl.md: single consumer, no test/support indirection); gate 274 green -- satisfied: yes
- AC-04.5 (non-test) DSL coercion contract (numeric parse, truthiness) ratified by hv and enforced in one canonical module -- evidence: hv ruling 2026-08-10 (strict; DD-8 as-built note incl. `:loose` deferral) + `Riffle.Predicate.Coerce` consumed by Evaluator and StandardLib (c10, 577d4f5); coerce_test.exs + evaluator strict-boundary suite -- satisfied: yes

## Acceptance Tests

### WP-01 -- D2 root-cause and verdict (status: Done)

_(no tests in this group)_

### WP-02 -- Scaffolding and CI gate (status: Done)

_(no tests in this group)_

### WP-03 -- Predicate engine port (status: Done)

- AT-03.1 (legacy) full ported suite under `mix test --warnings-as-errors` (237 passed: 61 doctests, 176 tests) -- covers AC-03.1 -- status: green
- AT-03.2 (legacy) test/riffle/extrication_gate_test.exs::"invariant: lib/ and test/ carry zero source-project traces" -- covers AC-03.2 -- status: green
- AT-03.3 (legacy) test/riffle/predicate/default_pipeline_resolution_test.exs (4 tests: configured resolution, unset-config raise, missing-predicate raise, default_pipeline/0) -- covers AC-03.3 -- status: green

### WP-04 -- PFIC transform and hydration consolidation (status: Done)

- AT-04.1 (legacy) test/riffle/predicate/resolver_test.exs (23 tests, red-first at c1: both source kinds, chains, cycles, invalid refs, bang messages) + default_pipeline_resolution_test.exs nil-source additions + the un-neutered filtering suite's pins holding across the reroute -- covers AC-04.1 -- status: green
- AT-04.3 (legacy) test/riffle/predicate/loop_cache_integration_test.exs::"invariant: the stream filter path shares the cached evaluation entry point" (red-first at c3: the stream path was re-evaluating cached items) -- covers AC-04.3 -- status: green

---

_Generated by Intent v3.0.0 from `thread.json`. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
