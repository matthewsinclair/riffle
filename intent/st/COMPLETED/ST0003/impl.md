# Implementation - ST0003: SIA pattern layer rewrite

## As built

Three modules, one shipped data file, and seven test files.

| Path                                      | What it is                                                              |
| ----------------------------------------- | ----------------------------------------------------------------------- |
| `lib/riffle/sia/sia.ex`                   | THE pattern layer. `run/4`, `metadata_keys/0`. One stage per loop.      |
| `lib/riffle/sia/pipelines.ex`             | THE pipeline source vocabulary. `fetch/2`, `default_name/0`.            |
| `lib/riffle/sia/default_pipeline.ex`      | Riffle's sense/infer/act definitions, module form. `pred_path/0`.       |
| `priv/sia/sia.pred`                       | The same definitions, file form.                                        |
| `test/riffle/sia/sia_test.exs`            | Staging order, results, ingest, the declared metadata key. Doctest host. |
| `test/riffle/sia/evidence_fence_test.exs` | The anti-D2 fences, over a declared matrix of seven run shapes.         |
| `test/riffle/sia/no_rescue_fence_test.exs`| The anti-D9 fence, plus a raising predicate propagating out of a run.   |
| `test/riffle/sia/sources_test.exs`        | The closed vocabulary; file-and-module equivalence with the cache off.  |
| `test/riffle/sia/characterisation_test.exs`| The nine inherited tests, all now asserting something.                 |
| `test/riffle/single_transition_fence_test.exs` | The knot is the only transition.                                   |
| `test/riffle/boundary_fence_test.exs`     | Four directions now: waist/engine both ways, and neither names the layer. |
| `test/support/{sia_fixtures,config_helpers}.ex` | Shared inputs and app-env preconditions.                          |

The run, as it actually fires:

```
RunStarted -> InputReceived
  -> per loop: StageEntered -> (Loop.filter) -> StageProgressed -> StageExited
  -> MetadataRecorded -> RunCompleted
```

Eleven emissions for a two-stage run, pinned as a literal in `sia_test`. The only impure step is the parenthesised one, and it sits strictly between two `tick/2` calls.

### The one statistic

`:stage_counts`, a keyword list of loop name to retained count, and it is computed as a projection of the `StageCompleted` emissions the run has already made rather than tallied alongside them. That is deliberate: the defect this thread exists to prevent was a tally that outlived the collection it counted. A keyword list rather than a map so two loops sharing a name stay two entries.

### Failure, in two kinds

A source that cannot produce the pipeline asked for -- missing file, unknown name, unconfigured default -- is a tagged error, and the run *fails*: `:failed`, the reason in `ctx.errors`, an `ErrorRaised` emission, and no `OutputProduced` anywhere in the stream. One perturbation does all of that (`RunFailed` already accumulates, transitions and emits), so reporting the error first would have recorded it twice.

A source outside the declared vocabulary raises, as does input outside the two ingest shapes. The line between the two kinds is whether a correct program could produce it at runtime.

## Mutation table

Every fence this thread added, broken on purpose, watched go red, restored. A fence that cannot fail is not a fence.

| #   | Mutation                                                        | Fence that went red                                  |
| --- | --------------------------------------------------------------- | ---------------------------------------------------- |
| M1  | `RunCompleted{output: []}` -- the D2 sin exactly                | evidence: results the same in all three places       |
| M2  | stage count reports `received` where it means `retained`        | evidence: every derived fact arrives with evidence   |
| M3  | metadata key renamed to `:results_available`                    | evidence: derived facts, and declared-keys           |
| M4  | a `rescue` added to the layer                                   | no-rescue AST fence                                  |
| M5  | `%Ctx{ctx \| status: ...}` in the layer                         | single-transition: struct-update, and map-update     |
| M6  | bare `%{item \| ...}` in the layer                              | single-transition: map-update                        |
| M7  | `alias Riffle.Sia` in an engine file -- the stitch re-forming   | boundary: the engine names no pattern-layer module   |
| M8  | `alias Riffle.Sia` in a waist file                              | boundary: the waist names no pattern-layer module    |
| M9  | `.pred` drifts from its module twin (`> 50` becomes `> 500`)    | sources: file and module produce identical results   |
| M10 | unresolvable source completes the run instead of failing it     | characterisation: the four that asserted nothing     |
| M11 | `Keyword.validate!` weakened to `Keyword.get`                   | sources: an unknown option is a loud error           |

### M9 found a real hole

The first run of M9 took **one** test red, and it should have taken four. The evaluation cache keys on the predicate's name and the item, and the file and the module share every predicate name -- so the first run of a row warmed the cache and every later run answered from that one entry, whichever source it came from. The file's own predicate bodies never executed. The three "from a file" characterisation tests were proving that the file *parses*, not that it *works*, and a deliberate drift between the two sources left them green.

The characterisation suite now runs with the cache disabled, for the reason recorded in its setup. The same mutation takes four tests red.

This is the second time in two threads that mutation testing found the fence rather than the code. It is worth the twenty minutes every time.

## Critic rounds

`intent critic elixir` (the headless runner, mechanical subset) over every file the thread touched.

**Round 1 -- 2 WARNING, both IN-EX-TEST-005** (control flow in a test): a `case` on `Application.fetch_env/2`'s two shapes, inside the setup of `sources_test` and `characterisation_test`.

Fixed at source, and fixed as a Highlander problem rather than a local one: the same save-and-restore block, `case` and all, existed in three suites -- the two new ones and `default_pipeline_resolution_test` from ST0001. `Riffle.ConfigHelpers` now owns it, the branch is a multi-clause private function, and restoration registers at the moment the value is set so a test that changes nothing needs no teardown.

**Round 2 -- clean.** No findings at or above `recommendation` across 19 files.

**Whole-tree sweep at `style`** (the lowest severity) turned up 7 CRITICAL IN-EX-TEST-001 in files this thread did not touch -- `assert is_map(pipeline)` and `assert is_struct(loop, Loop)`, inherited with the ST0001 port. Each was a shape assertion sitting immediately above concrete assertions on the same value, so the shape line proved nothing the next two lines did not.

Fixed, out of thread scope and deliberately: closing a thread whose entire subject is assertions that assert nothing, while leaving seven of them in the tree, would be incoherent. Each became a single struct-or-map pattern pinning type and values together, which is strictly stronger than the three lines it replaced. Recorded here rather than done quietly.

The tree is now clean at every severity across all 86 files.

## Two departures worth recording

**WP-02 was not written red-first.** WP-01 was: the tests went in, ran red for the right reason (`Riffle.Sia` undefined), then the module made them green. For WP-02 the sources and definitions were built first and the tests written against a probe run. The mutation checks (M9-M11) are what stand in for the red phase there, and M9 is the reason that substitution is not free -- a test written against working code can be written to pass for the wrong reason, and only the mutation exposed it.

**AC-01.4 was clarified before building.** The first draft fenced `%Riffle.Ctx{... | ...}` across `lib/`, which catches only the explicit spelling. The knot itself reaches its slots through bare `%{ctx | ...}`, and so would anything reaching in. The two-clause form that shipped -- no Ctx struct-update outside the waist, no map update at all inside the layer -- is what is actually provable, and it is stricter where it matters. The change is noted inline on the AC line rather than made silently.

## Technical details

**Why `ctx.input` holds items, not raw maps.** Ingest is eager and total; the run records what it converted. That makes a run replayable from `ctx.input` alone rather than depending on a conversion that is not itself recorded. The eagerness is tested through the stageless pipeline, which evaluates no predicate and touches no item -- if ingest were lazy, nothing would force the bad element and the run would report success over input it never converted.

**Why the layer contains no map update at all.** The fence for "the knot is the only transition" cannot name a type in the bare `%{x | ...}` form, so inside the layer it forbids the form outright. That over-constrains a little and is worth it: a thin coordinator that threads a context and builds perturbations has no business updating a map, and the constraint is what makes the invariant checkable rather than aspirational.

**`FenceHelpers` and the boundary fence moved up a level** (design DD-9). Both were project-level despite their names; adding two more namespaces to a file whose path said `ctx/` would have filed the pattern-layer invariants where nobody looks for them. `test/riffle/ctx/boundary_fence_test.exs` is now `test/riffle/boundary_fence_test.exs`, and ST0002's acceptance map cites the old path -- corrected there with a note rather than left stale.

## Gate

`mix gate` green throughout: `format --check-formatted`, `compile --warnings-as-errors --force`, `test --warnings-as-errors` (covering test compilation), `credo --strict`.

Final: **363 passed** (68 doctests, 295 tests), 642 mods/funs, zero credo findings, zero critic findings at any severity.
