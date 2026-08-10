---
verblock: "10 Aug 2026:v0.2: cc - Ratified contract authored (hv rulings 2026-08-10 applied)"
st_id: ST0001
title: "Extricate Predicate and SIA from Multiplyer -- acceptance contract"
---

# ST0001 Extricate Predicate and SIA from Multiplyer -- Acceptance

> Canonical acceptance contract for ST0001. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them. Real test code lives in the suite (paths cited below); this file is the contract plus the AC-to-AT coverage map plus live status. info.md / WP info.md reference this file and never restate ACs (one home).
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Change control: clarifying an AC or AT is verifier-and-builder; shrinking scope, or weakening an AT to make it pass, needs the owner.
>
> AT status vocabulary: to-write (red-first) | red | green | n/a (non-test: doc / eyeball / gate).
>
> Non-test ACs carry their state inline -- `-- evidence: <ref> -- satisfied: yes|no` on the AC line; test-backed ACs are satisfied by a green covering AT (computed, never written). Multi-AC coverage on an AT is comma-separated.
>
> Exemption (ST0048): the close-gate is fail-by-default -- a unit with an empty or missing contract is refused. A unit that is deliberately AC-free (eg a pure content / authorial task) declares `acceptance: exempt` in the frontmatter above; the gate then passes and announces the exemption. Omit it (the default) and the contract is enforced. Never inferred from emptiness; always declared.
>
> Ratified by hv 2026-08-10 with amendments: reference-material carry-over (former AC-04.1) removed -- nothing is copied from the source project; AC-03.2 strengthened to zero source-project traces of any kind in code.

## Acceptance Criteria

### ST-level

None -- WP-distributed.

### WP-01 -- D2 root-cause and verdict (status: Done)

- AC-01.1 (non-test) D2 root-caused with the engine-vs-glue verdict recorded, file:line evidence from real reads of the archive -- evidence: design.md "D2 verdict" section -- satisfied: yes

### WP-02 -- Scaffolding and CI gate (status: Done)

- AC-02.1 (non-test) CI runs format check + compile + test with warnings-as-errors covering test compilation, green on the skeleton before the port lands -- evidence: .github/workflows/ci.yml runs `mix gate` (the single local/CI gate alias in mix.exs); local `mix gate` green on skeleton 2026-08-10 (upstream Actions run lands on next hv push) -- satisfied: yes

### WP-03 -- Predicate engine port (status: WIP)

- AC-03.1 The ported engine and its full ported test suite are green under `mix test --warnings-as-errors` (D5 class structurally excluded)
- AC-03.2 Zero source-project traces in `lib/` and `test/` -- modules, atoms, app-env keys, strings, comments, moduledocs (hv ruling 2026-08-10)
- AC-03.3 Default-pipeline resolution is config-injected (`:riffle, :default_pipeline`); unset config surfaces an explicit error; the engine names no pattern-layer module
- AC-03.4 (non-test) Ported code and tests remediated against the rule library -- critic-elixir run on the ported tree with CRITICAL/HIGH findings fixed (hv rewrite-flexibility ruling 2026-08-10; DD-4 as amended) -- evidence: critic report + remediation commits -- satisfied: no

## Acceptance Tests

### WP-01

- Coverage: AC-01.1 is non-test; evidence carried on the AC line.

### WP-02

- Coverage: AC-02.1 is non-test; evidence carried on the AC line.

### WP-03

- AT-03.1 full ported suite under `mix test --warnings-as-errors` (237 passed: 61 doctests, 176 tests) -- covers AC-03.1 -- status: green
- AT-03.2 test/riffle/extrication_gate_test.exs::"invariant: lib/ and test/ carry zero source-project traces" -- covers AC-03.2 -- status: green
- AT-03.3 test/riffle/predicate/default_pipeline_resolution_test.exs (4 tests: configured resolution, unset-config raise, missing-predicate raise, default_pipeline/0) -- covers AC-03.3 -- status: green
- Coverage: complete -- AC-03.1..3 each covered by an AT above; non-test ACs (AC-01.1, AC-02.1, AC-03.4) carry evidence inline.
