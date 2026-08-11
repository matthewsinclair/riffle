---
verblock: "11 Aug 2026:v0.8: cc - ST0003 CLOSED; all three threads complete, the extraction is done"
---

# Work In Progress

## Current Focus

**Nothing in flight. All three steel threads are closed** and the extraction Riffle was created to perform is complete.

- **ST0001** -- the Predicate engine, ported with its tests, the one stitch inside ported code severed (11/11).
- **ST0002** -- `ctx-next`, the Bowtie waist: typed composite root, pure total knot, closed catalogs, delivery floor (17/17).
- **ST0003** -- the SIA pattern layer: the edge where the engine and the waist compose (22/22).

The system now has a shape that can be stated in one line and is held mechanically rather than by convention: **the engine names nothing, the waist names nothing, and the pattern layer names both while being named by neither.** `intent/docs/bedrock.md` carries the eight commitments, the seven negations, and the fence enforcing each.

The defect that started the whole extraction is gone at the level of _class_, not instance. The source layer computed correct results, derived statistics from them, discarded the results, and recorded a flag saying they were available -- and its tests read a structural default, so nothing could see it. In Riffle a completed run's results appear in three places that must agree, and the one statistic recorded is a projection of facts already emitted rather than a tally kept beside them. Both are fenced, both mutation-checked. Bedrock commitment 8 states the general form: no derived claim outlives its evidence.

## Active Steel Threads

None. ST0001, ST0002 and ST0003 are all under `intent/st/COMPLETED/`.

## Upcoming Work

Nothing is queued, and the next unit of work is hv's call. Three shapes it could take, roughly in order of how much they would teach:

1. **A second consumer.** Everything in Riffle currently has exactly one consumer, which is the honest reason several mechanisms were not built (no fan-out registry, no subscriber table, no datasource layer). A second consumer -- a fan-in source, or a second pattern layer over the same waist -- is what would show whether the separation is real or merely declared.
2. **A thin CLI.** The handoff always assumed Riffle would grow its own rather than port one. It is the smallest thing that makes the library usable by someone who is not writing Elixir.
3. **Publishing.** `mix hex.publish` is wired but deliberately off. The README, the licence and the module docs are in shape; the decision is whether the library is worth a version number yet.

## Backlog (filed, unscheduled -- most need an hv call)

- **Needs a ruling:** socrates handoff on the perturbation/emission structural twins (7 of 10 pairs are field-for-field, 4 knot transitions are pure renames -- is that duplication or is it the type system doing its job?); whether the measured-surface fence should parse `extrication-handoff.md` rather than hold a transcription of it; one error vocabulary for malformed DSL text at the loader boundary (a public contract change); socrates on a single definition-argument-shape recogniser in `Dsl.Statements`.
- **Needs a thread:** Cache perf (persistent_term flag + ets counters -- ST0001 DD-9/M4); cache key source-qualification (documented limitation -- the key is the predicate's _name_, so two sources defining the same name share an entry; ST0003 works around it by disabling the cache where equivalence is under test).
- **Does not need hv, but does need an agent invocation:** diogenes spec pass over the ten fence files.
- **Open question raised by ST0003:** should Riffle ship a `config/` that points `:default_pipeline` at `Riffle.Sia.DefaultPipeline`? It would make `:default_module` work out of the box, and it would also wire the example in as the default for everyone -- which is the framework smell the whole project has been avoiding. Left unconfigured; tests set it explicitly and the moduledoc says how.

## Notes

**Gate.** `mix gate` = format + compile (`--warnings-as-errors --force`) + test (`--warnings-as-errors`, covering test compilation) + `credo --strict`. One definition, run identically by local and CI (`.github/workflows/ci.yml`, push-to-main and all PRs). Final state: **363 passed** (68 doctests, 295 tests), 642 mods/funs, zero credo findings, and zero `intent critic elixir` findings at _any_ severity across all 86 files.

**Two things ST0003 found that are worth remembering.** First, mutation testing caught the test estate rather than the code, for the second thread running: the evaluation cache keys on a predicate's _name_, and the `.pred` file and its module twin share every name, so the "from a file" tests were proving the file parses rather than that it works. Only a deliberate drift between the two sources exposed it. Second, ST0002's correction of the "reference implementation" claim missed the README -- the most public document in the repo kept the struck sentence for a day. A ruling is not applied until it is applied everywhere; grep for it.

**Zero-trace rule** enforced structurally by `test/riffle/extrication_gate_test.exs`. `intent/` and the README are the declared scope exception.

**Push policy:** hv authorised; cc pushes at chunk boundaries. `main` is branch-protected upstream (required check `gate`, `enforce_admins: false`, so a direct push is a logged bypass). Remotes are `local` and `upstream` -- there is no `origin`.

## Context for LLM

Read `intent/docs/bedrock.md` FIRST -- it is the architectural contract, and a contradiction with it is a bug in the contradicting document. Then `intent/st/COMPLETED/ST0003/{design,impl}.md` for the pattern layer, `ST0002/` for the waist, `ST0001/` for the engine. `intent/restart.md` carries the bounce point; the whiteboard node board carries live session state.
