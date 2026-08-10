---
verblock: "10 Aug 2026:v0.5: cc - Restart context at localfold #4; ST0002 closed, ST0003 next, running autonomously"
---

# Restart Context

## Where things stand (2026-08-10, localfold #4)

Two threads closed today. **ST0001** (extricate the Predicate engine) and **ST0002** (ctx-next, the Bowtie waist) are both in `intent/st/COMPLETED/`, gates 11/11 and 17/17. Twenty-two commits pushed, CI green throughout, `mix gate` green (318 passed, credo zero).

**hv has authorised running autonomously from here** ("I let you run on your own until you can't go any further"). So: pick up ST0003 and take it as far as it goes, without waiting for a ruling on anything hv has already settled. The scope calls ST0003 owns were ratified in advance -- see below.

## Read these first

- `intent/docs/bedrock.md` -- **the architectural commitments**. A contradiction with it is a bug in the contradicting document, not a choice. Read it before writing any code.
- `intent/st/COMPLETED/ST0002/design.md` -- DD-1..DD-7, and the capability map.
- `intent/st/COMPLETED/ST0002/impl.md` -- as-built, both critic rounds, and the mutation checks.
- `intent/docs/extrication-handoff.md` -- the defect ledger and the stitch that must not re-form.
- `intent/llm/MODULES.md` -- the Highlander registry, now covering the waist.

## Next unit of work: ST0003, SIA on the waist

**First act, before any code:** `intent/st/ST0003/acceptance.md` is still the unfilled Intent template. Author the AC/AT contract -- the close-gate is fail-by-default and no WP can close against an empty one. Then `intent wp new` for the breakdown. ST0002's contract is the model: conformance fences where the property is a whole-class invariant, example tests only where it genuinely is an example.

**The design constraint that dominates this thread (ST0002 DD-5).** The Predicate engine is an *inferential edge*, not part of the knot. It is a rules engine -- which is inference -- and it is concretely impure, since evaluation runs through an ETS cache owned by a GenServer. Putting evaluation inside the knot would break purity outright. So SIA's shape is: an edge component evaluates predicates and feeds the typed result in as a perturbation; the knot threads run state and produces emissions. Both directions are fenced already (`boundary_fence_test`), so neither half can name the other -- the composition happens in ST0003's edge.

**What the thread delivers.** The five Multiplyer characterisation tests, pinned at `assert [] = results`, become this thread's ATs strengthened to `assert [%Item{} | _] = results`. Results are delivered **via emissions** -- D2's obligation, with no lying availability flag. D9's rescue-all swallow must not reproduce: real errors surface.

**Scope calls hv already ratified** (do not re-ask):

- `.pred` file pipelines are **in**. The loader is built, tested and green from ST0001; excluding it would leave working code unreachable.
- The CSV datasource is **out**, replaced by a plain ingest perturbation. It is a fan-in source, and a natural later addition that would then prove source independence.

**A likely shape, not a mandate.** The waist already carries `StageEntered` / `StageProgressed` / `StageExited` perturbations and their emission twins, which the sense/infer/act staging was sized for. Whether SIA needs domain perturbations beyond those is a real design question for the thread -- and adding a type means the two-step registry ritual plus a knot clause, with the delivery-floor fence catching a forgotten clause.

## Open items for hv (filed, not blocking)

- Two socrates handoffs from ST0002: the perturbation/emission structural twins (7 of 10 pairs are field-for-field, and 4 transitions are pure renames); and whether the measured-surface fence should parse `extrication-handoff.md` rather than hold a transcription of it.
- A diogenes spec pass on the seven ctx fence files.
- Cache perf (persistent_term + ets counters, ST0001 DD-9/M4); loader error-vocabulary unification (public contract change).

## Invariants (do not regress)

- Zero source-project traces in `lib/` + `test/` -- `extrication_gate_test.exs` enforces structurally
- The engine and the waist name each other in neither direction -- `boundary_fence_test.exs`, AST-based
- The knot stays unconditionally pure -- `purity_fence_test.exs` walks the compiled call closure
- Every perturbation yields a real emission, never the delivery floor -- `delivery_floor_fence_test.exs`
- A fence that cannot fail is not a fence: mutation-check every new one, and give it a positive control when its discriminator would otherwise never fire
- `mix gate` green before every commit; it includes `credo --strict`, and warnings-as-errors covers test compilation
- Archive (`~/Devel/_Archive/Multiplyer`) is read-only forensics
