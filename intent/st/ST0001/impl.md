# Implementation - ST0001: Extricate Predicate and SIA from Multiplyer

## Implementation

### WP-01 -- D2 root-cause (as-built)

Method: five characterisation tests re-run in the archive (12 passed, pins hold), then a stage-by-stage probe script (`mix run`, scratchpad-hosted, zero archive edits) against the 4-row characterisation dataset, then git pickaxe forensics. Full verdict + evidence: design.md "D2 verdict". Headline: the engine produces correctly tagged sense->infer->act items; the glue's `process/4` discards them after counting -- the `:results` cargo writes were deliberately removed in archive commit `e0b5dc2a` (2025-04-04). Nothing travelled with the port.

### WP-02 -- Gate (as-built)

`mix gate` alias in mix.exs = `format --check-formatted` + `compile --warnings-as-errors --force` + `test --warnings-as-errors`, with `preferred_envs: [gate: :test]` via `cli/0`. `.github/workflows/ci.yml` runs the same alias on erlef/setup-beam (Elixir 1.20.3 / OTP 29, matching the local toolchain) with deps/_build caching. One gate definition, two callers (Highlander). First upstream Actions run lands on the next hv push.

### WP-03 -- Mechanical port (as-built, commit 7b7f912)

- 15 engine files (~5.1k LOC) -> `lib/riffle/predicate/`; 21 test files (~3.5k LOC) -> `test/riffle/predicate/`; 2 data fixtures (`user_test.pred`, `users_small.csv`) -> `test/fixtures/`.
- Rename: sed over the copied tree (`Multiplyer.Predicate` -> `Riffle.Predicate`, `Multiplyer.{` -> `Riffle.{` for doctest multi-aliases). Residue after sed was exactly the 8 stitch lines the handoff predicted (pipeline.ex x4, loop.ex x3, macro.ex comment x1) -- severed by hand, by design not sed.
- Stitch severance (DD-1):
  - `Riffle.Predicate.default_pipeline/0` -- the one config surface (`Application.get_env(:riffle, :default_pipeline)`), nil when unset.
  - pipeline.ex both process-clause sites: `module = Map.get(pipeline, :module) || Riffle.Predicate.default_pipeline()`. The magic pattern-layer name list (`[:main, :sense_pipeline, :infer_pipeline]`) is gone; explicit module now outranks the default (the archive inverted that).
  - loop.ex reference resolution: the six silent always-false fallback shapes replaced by `resolve_reference!/2` + `Riffle.Predicate.UnresolvedPredicateError` raises naming the predicate, the module, and (when relevant) the config key. Try/rescue swallows around resolution are gone; real errors propagate.
- `Riffle.Application` supervises `Riffle.Predicate.Cache` (the archive app tree did the same); `mod:` added to mix.exs.
- D5: `expr_macro_direct_test.exs` piped the function into `Predicate.new/3` first position, making `name` a function and `function` a string -- a predicate that would crash if evaluated, which the suite therefore never did. Fixed to `new(name, description, function)`.
- Gate at land: 237 passed (61 doctests, 176 tests), zero warnings.

### WP-03 -- Remediation pass

_In progress: critic-elixir review (lib) + test-check (test) running; CRITICAL/HIGH fixed per DD-4-as-amended, findings + dispositions recorded here._

## Technical Details

- Loop/pipeline resolution failure semantics changed from silent-degrade to raise. The engine's own last-resort (`evaluate_direct` on an unresolved reference) already raised; resolution now matches it.
- The zero-trace gate (AT-03.2) assembles its needle at runtime (`"multi" <> "plyer"`), so it scans every file under lib/ and test/ with no exclusions, itself included.
- `.pred` fixture usage-example comments were renamed with the API (they document the current API truthfully).

## Challenges & Solutions

- Ported suite initially failed 62 tests: the archive's test_helper ran `Application.ensure_all_started(:multiplyer)` and its app tree supervised the engine cache. Solution: minimal `Riffle.Application` supervising the cache -- not a test_helper hack -- because the cache is engine infrastructure, not test scaffolding.
