# Tasks - ST0001: Extricate Predicate and SIA from Multiplyer

## Tasks

### WP-01 -- D2 root-cause and verdict

- [x] Run the five characterisation tests in the archive (read-only) -- 12 passed, pins hold
- [x] Trace `process/4` -> `prepare_data/1` -> `load_pipeline/2` -> `execute_sia_pipeline/3`; find the empty-set step -- engine produces tagged items; glue discards them
- [x] Classify engine-vs-glue; record verdict + file:line evidence in design.md -- VERDICT: glue (`sia.ex` never writes cargo `:results`; removed in `e0b5dc2a`)
- [x] If engine-side: add a red-first AT to WP-03 scope (contract amendment) -- n/a, verdict is glue-side; no contract change

### WP-02 -- Scaffolding and CI gate

- [x] Local gate: `mix gate` alias = format --check-formatted, compile --warnings-as-errors --force, test --warnings-as-errors
- [x] `.github/workflows/ci.yml` -- runs the same `mix gate` alias (Highlander: one gate definition)
- [x] Gate green on the empty skeleton (2026-08-10); placeholder hello-world replaced with honest minimal module + doctest

### WP-03 -- Predicate engine port

- [x] Copy `predicate/` sources + tests + 2 data fixtures (user_test.pred, users_small.csv)
- [x] Write AT-03.2 zero-trace gate and AT-03.3 config-resolution tests
- [x] Mechanical rename per the design map (sed over tree; residue was exactly the 8 stitch lines)
- [x] Sever stitch 1 (DD-1): config-injected resolution; 6 silent always-false fallbacks in loop.ex replaced with UnresolvedPredicateError raises; magic name list [:main, :sense_pipeline, :infer_pipeline] removed from pipeline.ex; macro.ex comment scrubbed
- [x] Riffle.Application supervises engine cache (mirrors source app tree)
- [x] Fix D5 arg shape (pipe fed fn as name, function was a string -- never evaluated by tests)
- [x] Full suite green under the gate: 237 passed (61 doctests, 176 tests) -- mechanical-port commit 7b7f912
- [x] Remediation pass (layered, gate green each step):
  - R1 (29eac91): 5 lib CRITICALs -- exact-term cache keys, loud create/1 contract, registry state-resolution (always-true stubs gone), construction-time date raise, config probe-not-rescue; registry merge/load dedup
  - R2 (335a655): hydrate-at-generation in Dsl.Macro (refs resolve through defining module or raise; bodies hydrate once); 6 test CRITICALs -- four neutered filtering tests un-neutered with exact survivor/tag pins, short-circuit hedges pinned exact, start_supervised!
  - R3 (bea85fa): Cache.reset_stats/0 + config/0 public API (three :sys.replace_state blocks gone), per-test tmp_dir fixtures, registry suite async, async opt-out comments, prior-config restore
  - Structural WARNINGs (hydration x6, dual evaluation path, STD twin, coercion drift, expr-family test dup) dispositioned to WP-04 per DD-7

### WP-04 -- PFIC transform and hydration consolidation (DD-7)

- [ ] socrates design pass on the single-resolver consolidation
- [ ] One resolver module; route pipeline/loop/registry/loader/macro through it
- [ ] Collapse Loop process/filter onto one evaluation entry point (cache honoured)
- [ ] Delete the STD twin; one access path
- [ ] macro/parser block-level silent drops -> raise
- [ ] Consolidate expr-macro test family; delete scratch files
- [ ] hv ruling on DSL coercion contract; canonical coercion module
- [ ] critic-elixir re-run: zero CRITICAL, zero Highlander/PFIC WARNINGs

## Task Notes

WP-01 is time-boxed (~2h): on overrun, record the partial trace and escalate to hv rather than stall.

## Dependencies

WP-01 precedes WP-03 (the verdict may add a red-first AT). WP-02 precedes WP-03 (the gate exists before ported code lands). WP-01 and WP-02 are independent of each other.
