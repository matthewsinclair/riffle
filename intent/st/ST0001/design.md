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

_Pending WP-01._ Protocol: run the five characterisation tests in the archive (`test/multiplyer/sia/sia_pipeline_test.exs`, pinned `assert [] = results`); trace `sia.ex` `process/4` -> `prepare_data/1` -> `load_pipeline/2` (`:default_module` branch, `sia.ex:149-152`) -> `execute_sia_pipeline/3`; identify the step that produces the empty set; classify engine (travels with the port; becomes a red-first AT here) vs glue (dies in ST0003's rewrite; recorded there). Evidence at file:line, from real reads.

## Design Decisions

- **DD-1 Stitch-1 severance -- config-injected default pipeline.** The archive engine hardcodes a pattern-layer fallback (`pipeline.ex:138,182`, `loop.ex:205-208`, comment at `dsl/macro.ex:94`). In Riffle the engine resolves its default pipeline from application config (`:riffle, :default_pipeline`); when unset, the failure is explicit (tagged error or raise with a clear message -- final shape recorded at implementation against the real call sites). The engine never names a pattern-layer module. No Silent Errors: unset config surfaces; it never nil-glides.
- **DD-2 Zero source-project traces in code (hv ruling, 2026-08-10).** No references to the source project anywhere in `lib/` or `test/` -- modules, atoms, app-env keys, strings, comments, moduledocs. Enforced by AT-03.2: a gate test that scans `lib/` + `test/` with a runtime-constructed needle (so the gate never contains the literal it hunts). Scope boundary: the `intent/` extrication record and the README status paragraph are hv-authored and stay.
- **DD-3 No reference-material carry-over (hv ruling, 2026-08-10).** SIA glue, `sia.pred`, and datasource stay in the archive and are read in place for ST0003. Nothing is copied into this repo.
- **DD-4 Port discipline: nearly-as-is.** No opportunistic refactors during the port -- the diff stays auditable against the source. A `critic-elixir` advisory pass at the end logs findings for a later thread; it does not gate ST0001.
- **DD-5 D5 subsumed by the gate.** The arg-shape warning in the ported DSL test is fixed at port; with warnings-as-errors covering test compilation, its class cannot recur (AC-03.1 proves it).
- **DD-6 Push policy (hv ruling, 2026-08-10).** Commit locally as work lands; hv pushes upstream when a chunk is public-worthy (also meters CI cost). cc does not push unprompted.

## Architecture

The ported engine is a self-contained subtree: `Riffle.Predicate` (item, predicate, pipeline, pipeline-config, loop, cache, registry, standard-lib, DSL). It references nothing outside itself except stdlib/OTP -- measured Ctx-free at extraction, and pattern-layer-free by DD-1. ST0002's waist and ST0003's pattern layer sit ABOVE it; dependency arrows only ever point up into the engine, never out of it.

## Alternatives Considered

- **Copy reference material with provenance headers** (the original WP-04): rejected by hv -- read in the archive instead; keeps the repo clean of source-project traces.
- **Port under the source namespace, rename later**: rejected -- the zero-trace gate would be unsatisfiable mid-stream, and a second namespace invites Highlander drift.
- **Runtime `Code.ensure_loaded?` fallback retained under a Riffle-named module**: rejected -- reproduces the stitch shape; config injection keeps the engine ignorant of any specific pattern layer.
