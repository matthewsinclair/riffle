---
verblock: "10 Aug 2026:v0.7: cc - ST0002 CLOSED (the waist); ST0003 next, running autonomously"
---

# Work In Progress

## Current Focus

**ST0002 is CLOSED** (2026-08-10, gate 17/17; moved to `intent/st/COMPLETED/ST0002`), joining ST0001. `ctx-next` is built to the Bowtie shape and fenced rather than merely intended: a typed composite root with one declared overlay and no pass-through accessors, a pure total knot (`Riffle.Ctx.Knot.tick/2`) whose purity is proved by walking the compiled call closure, two closed catalogs sharing one registry mechanism, and a delivery floor no perturbation escapes. The measured 24-function surface is covered by enumeration in both directions. `intent/docs/bedrock.md` now records the commitments, the negations, and the fence holding each one.

Two critic rounds ran and everything at or above the ratified bar was fixed at source. The instructive finding: one of my own fences was dead -- the Erlang remote-type form carries three list elements and I matched two, so the "no slot accumulates catalog types" check had been unfalsifiable since it was written. Two fences now carry positive controls, and every fence in the thread was mutation-checked.

**Next: ST0003**, running autonomously (hv, 2026-08-10). Its acceptance contract is the first act -- see `intent/restart.md`.

## Active Steel Threads

- ST0003 (WIP, unstarted): SIA on the waist -- red-first; the five characterisation tests pinned at `assert [] = results` become its ATs, strengthened to `assert [%Item{} | _] = results`. Results delivered via emissions (D2; no lying availability flag); D9 rescue-all must not reproduce. Dominated by ST0002 DD-5: the Predicate engine is an inferential edge, never inside the knot, so SIA composes the two halves at that edge.

## Upcoming Work

- ST0003 kickoff: author acceptance.md, then WP breakdown (scope calls already ratified: `.pred` in, CSV datasource out)
- Backlog (filed, unscheduled): Cache perf fix (persistent_term flag + ets counters -- DD-9/M4); socrates handoff on Macro vs DefaultPipelineConfig accessor generation; socrates on the perturbation/emission structural twins and on whether the measured-surface fence should parse the handoff doc; diogenes spec pass on the seven ctx fences; socrates question on a single definition-argument-shape recogniser in Dsl.Statements (R4b critic, deferred with calibration reasoning); one error vocabulary for malformed DSL text at the loader boundary (public-shape decision); diogenes test-spec pass; cache key source-qualification (documented limitation)

## Notes

CI/CD state (2026-08-10): CI is `.github/workflows/ci.yml` on push-to-main + all PRs, running the same `mix gate` alias as local (one gate definition, two callers); green on every run today. `mix gate` is now format + compile + test + `credo --strict`, so CI enforces the static-analysis baseline too; `bin/riffle test all` is green end to end (286 tests, 411 mods/funs, zero credo findings). `main` is branch-protected upstream -- required check `gate`, strict, force-push and deletion blocked, `enforce_admins: false` so the direct-to-main push policy is unchanged (GitHub reports each direct push as a logged bypass). There is NO CD by decision: devbin ships no `release`, and its opt-in `publish` (default `mix hex.publish`) stays off until Riffle is more than the engine half.

Zero-trace rule (DD-2) enforced structurally by `test/riffle/extrication_gate_test.exs`. Rulings log: ST0001 design.md DD-1..DD-9 (now under COMPLETED/); verbatim session logs in `intent/whiteboard/cc/.history/20260810/`. Push policy: hv authorised ("push away"); cc pushes at chunk boundaries; CI runs `mix gate` identically to local. Peer-session work landed on main this evening (hv-driven): the bin/riffle launcher rename (026310b) and credo + fleet .credo.exs (fb3e34a) -- credo cleanup of the 21 remaining baseline findings belongs to that workstream, not cc (R4b's delta: -1, zero added).

## Context for LLM

Read `intent/docs/bedrock.md` FIRST -- it is the architectural contract, and a contradiction with it is a bug in the contradicting document. Then `intent/st/COMPLETED/ST0002/{design,impl}.md` for the waist and `intent/st/COMPLETED/ST0001/{design,impl}.md` for the engine; `intent/restart.md` carries the bounce point; the whiteboard node board carries live session state.
