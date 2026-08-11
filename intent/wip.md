---
verblock: "11 Aug 2026:v0.9: cc - ST0005 CLOSED; all five threads complete, the project is done to its charter"
---

# Work In Progress

## Current Focus

**Nothing in flight. All five steel threads are closed**, and Riffle does everything it was created to do: the extraction is complete, the library has a way in, a command line, and a documentation surface that is checked rather than asserted.

- **ST0001** -- the Predicate engine, ported with its tests, the one stitch inside ported code severed (11/11).
- **ST0002** -- `ctx-next`, the Bowtie waist: typed composite root, pure total knot, closed catalogs, delivery floor (17/17).
- **ST0003** -- the SIA pattern layer: the edge where the engine and the waist compose (22/22).
- **ST0004** -- the service and the CLI: `Riffle.Service` holds the business logic, `arca_cli` and `mix riffle.cli` are both thin coordinators over it (26/26).
- **ST0005** -- documentation: the moduledoc pass, `ex_doc` grouped by the five layers, and the `.pred` language reference (17/17).

The system has a shape that can be stated in one line and is held mechanically rather than by convention: **five layers, each naming the one below it and named by none of them.** The engine names nothing, the waist names nothing, the pattern layer names both, the service names the pattern layer and no delivery mechanism, and the CLI names the service and nothing beneath it. `intent/docs/bedrock.md` carries the eleven commitments, the eleven negations, and the fence enforcing each.

The defect that started the whole extraction is gone at the level of _class_, not instance. The source layer computed correct results, derived statistics from them, discarded the results, and recorded a flag saying they were available -- and its tests read a structural default, so nothing could see it. In Riffle a completed run's results appear in three places that must agree, and the one statistic recorded is a projection of facts already emitted rather than a tally kept beside them. Both are fenced, both mutation-checked. Bedrock commitment 8 states the general form: no derived claim outlives its evidence.

## Active Steel Threads

None. ST0001 through ST0005 are all under `intent/st/COMPLETED/`.

## Upcoming Work

Nothing is queued, and the next unit of work is hv's call. Three shapes it could take, roughly in order of how much they would teach:

1. **A second consumer.** Almost everything in Riffle still has exactly one consumer, which is the honest reason several mechanisms were not built (no fan-out registry, no subscriber table, no datasource layer). A second consumer -- a fan-in source, or a second pattern layer over the same waist -- is what would show whether the separation is real or merely declared. ST0004 was a partial version of this experiment and the separation held: the CLI was built without touching the engine, the waist or the pattern layer at all.
2. **Publishing.** `mix hex.publish` is wired but blocked, not deliberate: `arca_cli` and `arca_config` are GitHub dependencies rather than hex packages, so Riffle cannot be published while the CLI is a runtime dependency. hv has moving them to hex on the plan, and Riffle's own publication unblocks with it. The README, the licence, the module docs and the generated reference are all in shape; what is left is a version number and a decision.
3. **Streaming, persistence, or a datasource layer.** The three things the README says are not here yet. Each is a real thread rather than a task, and none of them has a consumer asking for it, which is exactly why none was built.

## Backlog (filed, unscheduled -- most need an hv call)

- **Needs a ruling:** socrates handoff on the perturbation/emission structural twins (7 of 10 pairs are field-for-field, 4 knot transitions are pure renames -- is that duplication or is it the type system doing its job?); whether the measured-surface fence should parse `extrication-handoff.md` rather than hold a transcription of it; one error vocabulary for malformed DSL text at the loader boundary (a public contract change); socrates on a single definition-argument-shape recogniser in `Dsl.Statements`.
- **Needs a thread:** Cache perf (persistent_term flag + ets counters -- ST0001 DD-9/M4); cache key source-qualification (documented limitation -- the key is the predicate's _name_, so two sources defining the same name share an entry; ST0003 works around it by disabling the cache where equivalence is under test).
- **Does not need hv, but does need an agent invocation:** diogenes spec pass over the fence files.
- **Settled during ST0004/ST0005, recorded so it is not reopened without new information:** Riffle ships no `config/` pointing `:default_pipeline` at `Riffle.Sia.DefaultPipeline` -- it would wire the example in as everyone's default, which is the framework smell the project has avoided throughout. `docs/` carries exactly one file, the `.pred` language reference, because devbin help and `--help` own the command surface and `bedrock.md` owns the architecture; a second copy of either would drift.

## Notes

**Gate.** `mix gate` = format + compile (`--warnings-as-errors --force`) + test (`--warnings-as-errors`, covering test compilation) + `credo --strict`. One definition, run identically by local and CI (`.github/workflows/ci.yml`, push-to-main and all PRs). Final state: **484 passed** (90 doctests, 394 tests), 790 mods/funs, zero credo findings, and zero `intent critic elixir` findings at _any_ severity across all 108 files. `mix docs` is clean at zero warnings.

**Four things the five threads found that are worth remembering.**

First, mutation testing repeatedly caught the _test estate_ rather than the code. ST0002 had a fence that matched the Erlang remote-type form with the wrong arity and so recognised nothing. ST0003 found that the evaluation cache keys on a predicate's _name_, and the `.pred` file and its module twin share every name, so the "from a file" tests were proving the file parses rather than that it works. ST0004's decisive mutation hardcoded the stage summary and left every shipped-pipeline test green -- only a four-loop pipeline caught it, which is precisely how the archived CLI shipped its defect.

Second, a ruling is not applied until it is applied everywhere. ST0002's correction of the "reference implementation" claim missed the README for a day. ST0005 found the root moduledoc still teaching the tag-prefix stage model that ST0003 had refuted and ST0004 had fenced out of the CLI. This globalfold found `bedrock.md` itself two layers behind: the README had been claiming for a day that bedrock carried the commitments for all five layers, and it carried three. Grep before closing, and grep the documents that are supposed to be authoritative first.

Third, verifying the paths a builder exercises says nothing about the paths a new user reaches first. Every `sia.*` subcommand was green and the binding was reported as working; `bin/riffle cli` with no arguments raised on an unset `:url`, because the intro banner reads configuration the subcommands never touch.

Fourth, a documentation claim that a machine can check and does not is a claim that will be wrong eventually. Forty-four lines of `iex>` examples had never run, three of them wrong, including one that could not compile -- in a tree where every architectural claim was fenced.

**Zero-trace rule** enforced structurally by `test/riffle/extrication_gate_test.exs`. `intent/` and the README are the declared scope exception.

**Push policy:** hv authorised; cc pushes at chunk boundaries. `main` is branch-protected upstream (required check `gate`, `enforce_admins: false`, so a direct push is a logged bypass). Remotes are `local` and `upstream` -- there is no `origin`.

## Context for LLM

Read `intent/docs/bedrock.md` FIRST -- it is the architectural contract, and a contradiction with it is a bug in the contradicting document. Then `README.md`, which routes to everything else. Then the thread you need: `intent/st/COMPLETED/ST0005/` for the documentation discipline, `ST0004/` for the service and the CLI, `ST0003/` for the pattern layer, `ST0002/` for the waist, `ST0001/` for the engine. `intent/llm/MODULES.md` is the Highlander registry and covers every module including test support. `intent/restart.md` carries the bounce point; the whiteboard node board carries live session state.
