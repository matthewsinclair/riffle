# Design - ST0001: Extricate Predicate and SIA from Multiplyer

## Approach

Gates before code, diagnosis before port:

1. **WP-01 first** (per the handoff): root-cause D2 in the archive, read-only, and record the engine-vs-glue verdict below. The verdict decides whether the port carries a red-first bug fix.
2. **WP-02**: the quality gate exists before any ported line lands -- `mix format --check-formatted`, compile and `mix test --warnings-as-errors` with the flag covering TEST compilation, wired locally and in `.github/workflows/ci.yml`. Green on the empty skeleton proves the gate itself.
3. **WP-03**: the port, in a strict order that makes the two safety ATs genuinely red-first:
   1. Copy `predicate/` sources + tests into place (still source-namespaced -- will not compile).
   2. Write AT-03.2 (zero-trace grep gate) and AT-03.3 (config-injected default pipeline) -- both RED.
   3. Mechanical rename (see map), sever stitch 1, fix D5.
   4. Full suite green under the gate; ATs green.

### Rename map (WP-03)

| Source                         | Riffle                     |
| ------------------------------ | -------------------------- |
| `lib/multiplyer/predicate/**`  | `lib/riffle/predicate/**`  |
| `Multiplyer.Predicate.*`       | `Riffle.Predicate.*`       |
| `test/multiplyer/predicate/**` | `test/riffle/predicate/**` |
| `:multiplyer` app-env keys     | `:riffle`                  |
| moduledoc/comment source refs  | scrubbed (DD-2)            |

## D2 verdict (WP-01 deliverable)

**VERDICT: SIA glue. The defect does not travel with the Predicate port; it dies in ST0003's rewrite. No engine fix required.** (Recorded 2026-08-10. Method: five characterisation tests re-run in the archive -- 12 passed, pins hold -- then a stage-by-stage probe script run via `mix run` against the 4-row characterisation dataset. Zero archive edits.)

Stage evidence:

1. `DefaultPipeline.get_pipeline(:main)` returns a real `%Multiplyer.Predicate.Pipeline{}` (name `:main`, signal/inference/action loops). The `:default_module` branch (`sia.ex:149-152`) is NOT the failing step.
2. `Sia.prepare_data/1` yields a lazy stream of 4 `%Predicate.Item{}` structs. Fine.
3. `Sia.execute_sia_pipeline/3` -- and the raw unrescued `execute_pipeline/2` -- produce **2 correctly tagged items** with full sense->infer->act chains (eg `[:action_create_upsell, :action_send_promotion, :inference_upsell_opportunity, :inference_high_value_user, :signal_high_activity]`). **The engine works.** (2-of-4 is the pipeline filtering non-matching items -- by design.)
4. Full `process/2`: no errors; stats recorded (signal 3, inference 3, action 3, items_processed 2); cargo `:results_available` = `true`; cargo `:results` = NOT SET.

Root cause: `Multiplyer.Sia.process/4` never writes cargo `:results`. `update_statistics/3` (archive `sia.ex:469-525`) materialises the results stream (`sample = results_stream |> Enum.to_list()`, line 472), derives tag counts, and DISCARDS the materialised results. The success path sets only `:results_available, true` -- a flag that lies: results are precisely NOT available. The characterisation tests read `Ctx.get_cargo_item(ctx, :results, [])` (`sia_pipeline_test.exs:79` etc) and get the DEFAULT `[]` structurally, regardless of engine behaviour.

Causal history (git forensics): commit `e0b5dc2a` ("SIA+Predicate: final cleanup", 2025-04-04) deliberately removed both `Ctx.set_cargo_item(:results, ...)` writes from `sia.ex` ("Return the updated context with statistics only"), leaving no results-delivery path. The engine beneath was and is sound.

ST0003 implications (recorded here, consumed there):

- The rewrite must DELIVER results to the consumer (via ctx-next typed emissions), not merely count them -- exactly what the strengthened ATs (`assert [%Item{} | _] = results`) enforce.
- The `:results_available` lying-flag shape must not recur.
- Expect filtered output: N in, <=N tagged out (riffles catch, streams flow).

## Design Decisions

- **DD-1 Stitch-1 severance -- config-injected default pipeline.** The archive engine hardcodes a pattern-layer fallback (`pipeline.ex:138,182`, `loop.ex:205-208`, comment at `dsl/macro.ex:94`). In Riffle the engine resolves its default pipeline from application config (`:riffle, :default_pipeline`); when unset, the failure is explicit (tagged error or raise with a clear message -- final shape recorded at implementation against the real call sites). The engine never names a pattern-layer module. No Silent Errors: unset config surfaces; it never nil-glides.
- **DD-2 Zero source-project traces in code (hv ruling, 2026-08-10).** No references to the source project anywhere in `lib/` or `test/` -- modules, atoms, app-env keys, strings, comments, moduledocs. Enforced by AT-03.2: a gate test that scans `lib/` + `test/` with a runtime-constructed needle (so the gate never contains the literal it hunts). Scope boundary: the `intent/` extrication record and the README status paragraph are hv-authored and stay.
- **DD-3 No reference-material carry-over (hv ruling, 2026-08-10).** SIA glue, `sia.pred`, and datasource stay in the archive and are read in place for ST0003. Nothing is copied into this repo.
- **DD-4 Port discipline: quality over fidelity (AMENDED by hv ruling, 2026-08-10).** Original: nearly-as-is, no opportunistic refactors, critic advisory-only. hv amendment: Riffle is a fresh start informed by SIA -- rewrite whatever needs rewriting, code and tests, so the rewrite is worthwhile. Operationalised: the engine's architecture and semantics still port (the engine is the asset), but archive shapes that conflict with the rule library (PFIC, No Silent Errors, strong assertions, async tests, control-flow-free tests) are FIXED during the port, not preserved. The critic-elixir pass is remediation, not advisory. Commits stay layered -- mechanical port first, then remediation with a green suite at each step -- so the transformation is reviewable.
- **DD-5 D5 subsumed by the gate.** The arg-shape warning in the ported DSL test is fixed at port; with warnings-as-errors covering test compilation, its class cannot recur (AC-03.1 proves it).
- **DD-6 Push policy (hv ruling, 2026-08-10).** Commit locally as work lands; hv pushes upstream when a chunk is public-worthy (also meters CI cost). cc does not push unprompted.
- **DD-7 PFIC transform campaign (hv ruling, 2026-08-10, mid-session).** The ported engine gets PFIC-transformed, not just critic-patched -- the archive-era conditional pyramids do not meet house rules and the rewrite must be worthwhile. Merged with the critic's hydration finding (six hydration/resolution sites with four different failure behaviours) into WP-04: one loud resolver, pattern-matched clause heads, tagged tuples, file-by-file with the gate green at every step. Sequencing: WP-03's correctness criticals and un-neutered tests land FIRST -- they pin the behaviour the transform must preserve. PFIC-as-you-touch applies immediately to all new/edited code.
- **DD-8 DSL coercion contract: strict by default (hv ruling, 2026-08-10, post-compact).** Garbage input never matches. Numeric coercion accepts full parses only -- `to_integer("12abc")` is an error, not `12`; the archive's forgiving-zero default is dead. Truthiness is a defined enumeration, not accidental. The contract lives in ONE canonical coercion module consumed by Evaluator and StandardLib alike (Highlander). hv authorised an optional `:loose` mode "only if that is easy to do": include it only if it falls out as a trivial parameter default on the canonical module without threading a mode through the DSL; otherwise ship strict-only and record the deferral. Enforced by AC-04.5.
- **DD-9 Single resolver design (socrates pass, 2026-08-10).** One module `Riffle.Predicate.Resolver` owns reference resolution AND hydration for predicates, loops, and pipelines. A *source* is a module exporting `get_predicate/1` (+ `get_loop/1`, `get_pipeline/1`), a definitions map (`%{predicates: %{}, loops: %{}, pipelines: %{}}` -- registry state, loader instances), or `nil`. Source variance is confined to one private `lookup/3`; `nil` falls back to `Riffle.Predicate.default_pipeline/0` lazily at lookup time (inline bodies resolve without touching env), and a needed-but-absent source is `{:no_source, name}` whose message cites `config :riffle, :default_pipeline` (AT-03.3 pin holds). Tagged core (`resolve_predicate/2`, `resolve_loop/2`, `resolve_pipeline/2` returning `{:ok, runnable}` or `{:error, {:unresolved | :invalid_ref | :no_source | :cycle, ...}}`, reasons 3-ary, no source term inside) + bang wrappers raising `UnresolvedPredicateError` -- fetch/fetch! duality, error text built in one private describe. Hydration is inside resolution: output is always runnable (bodies materialised exactly once via `Predicate.create/1`, which absorbs the loader's raw-AST expr head); structs are re-walked, never trusted; no benign catch-all anywhere; ref-chasing carries a seen-path and cycles are tagged. Streams unify on the CACHED evaluation path (`Loop.filter` defined via `Loop.process`; AC-04.3): exact-term cache keys make tag accumulation position-qualify entries deterministically, so caching streams is semantically sound -- the archive's uncached fork protected a Cache implementation flaw (a GenServer call per lookup), filed as follow-up work, not a reason to fork evaluation. `Registry.get_predicate` returns the hydrated definition map (the callable wrapper was lossy and type-drifting). Evaluation deletes its unresolved-shape clauses with NO replacement raise -- `evaluate/2`'s head tightens to `%{name: _, function: _}` and `FunctionClauseError` is the honest invariant-breach signal. Deletions (no callers or subsumed): `Pipeline.hydrate_pipeline/hydrate_loop/hydrate_predicate`, `Pipeline.validate_has_main_pipeline`, `Pipeline.create/2,3`, `Pipeline.filter/2` alias, `Loop.create/2,3`, `Loop.resolve_reference!/2`, `Dsl.Macro.hydrate_predicate_ref!/hydrate_loop_ref!`, `Loader.create_predicate_function` (incl. its dead `{:call, ...}` clause), `Registry.ensure_loop_struct/ensure_pipeline_struct/resolve_predicates/resolve_loops/create_callable_predicate`. Follow-ups filed, out of WP-04 scope: Cache perf (persistent_term enabled-flag + ets counters for stats); cache keys are not source-qualified (flat predicate namespace, documented).

## Architecture

The ported engine is a self-contained subtree: `Riffle.Predicate` (item, predicate, pipeline, pipeline-config, loop, cache, registry, standard-lib, DSL). It references nothing outside itself except stdlib/OTP -- measured Ctx-free at extraction, and pattern-layer-free by DD-1. ST0002's waist and ST0003's pattern layer sit ABOVE it; dependency arrows only ever point up into the engine, never out of it.

## Alternatives Considered

- **Copy reference material with provenance headers** (the original WP-04): rejected by hv -- read in the archive instead; keeps the repo clean of source-project traces.
- **Port under the source namespace, rename later**: rejected -- the zero-trace gate would be unsatisfiable mid-stream, and a second namespace invites Highlander drift.
- **Runtime `Code.ensure_loaded?` fallback retained under a Riffle-named module**: rejected -- reproduces the stitch shape; config injection keeps the engine ignorant of any specific pattern layer.
