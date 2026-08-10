---
verblock: "10 Aug 2026:v0.6: cc - ST0001 CLOSED + credo zero in the gate; ST0002/ST0003 next"
---

# Work In Progress

## Current Focus

**ST0001 is CLOSED** (2026-08-10, gate 11/11 satisfied; moved to `intent/st/COMPLETED/ST0001`). The Predicate engine is extricated, PFIC-transformed, and critic-clean: one resolution path (Resolver, DD-9), one evaluation entry point (Loop.process, streams cached), one coercion contract (Coerce strict, DD-8), one DSL block grammar (Dsl.Statements), one top-level dispatch whose catch-all is the completeness check, and a genuinely working STD surface (`call` head + `expand_std/1` at `Predicate.create/1` -- R4b exposed and fixed the advertised-but-dead call syntax). Post-close, credo went from a 21-finding baseline to zero and joined the gate (addendum in ST0001 impl.md). Suite 286 green; seventeen commits pushed today, CI green on every one.

**Next: ST0002 then ST0003**, in that order (ST0003 is blocked on the waist). hv sequenced both on 2026-08-10; scope and plan still need ratification at kickoff.

## Active Steel Threads

- ST0002 (WIP, unstarted): ctx-next, the Bowtie waist -- REBUILD to the published spec, not a port. Doc set exists; `acceptance.md` is still the unfilled template, so authoring + ratifying that contract is the first act (the close-gate is fail-by-default). Measured minimum surface = the 24 Ctx functions the extricated code actually consumes, by call-site count, in `intent/docs/extrication-handoff.md`.
- ST0003 (WIP, unstarted): SIA pattern layer rewrite -- red-first against ctx-next; the five characterisation tests pinned at `assert [] = results` become its ATs, strengthened to `assert [%Item{} | _] = results`. D2 implications in ST0001 design.md (deliver results via emissions; no lying availability flag); D9 rescue-all must not reproduce.

## Upcoming Work

- ST0002 kickoff: author acceptance.md, ratify with hv, then WP breakdown
- Backlog (filed, unscheduled): Cache perf fix (persistent_term flag + ets counters -- DD-9/M4); socrates handoff on Macro vs DefaultPipelineConfig accessor generation; socrates question on a single definition-argument-shape recogniser in Dsl.Statements (R4b critic, deferred with calibration reasoning); one error vocabulary for malformed DSL text at the loader boundary (public-shape decision); diogenes test-spec pass; cache key source-qualification (documented limitation)

## Notes

CI/CD state (2026-08-10): CI is `.github/workflows/ci.yml` on push-to-main + all PRs, running the same `mix gate` alias as local (one gate definition, two callers); green on every run today. `mix gate` is now format + compile + test + `credo --strict`, so CI enforces the static-analysis baseline too; `bin/riffle test all` is green end to end (286 tests, 411 mods/funs, zero credo findings). `main` is branch-protected upstream -- required check `gate`, strict, force-push and deletion blocked, `enforce_admins: false` so the direct-to-main push policy is unchanged (GitHub reports each direct push as a logged bypass). There is NO CD by decision: devbin ships no `release`, and its opt-in `publish` (default `mix hex.publish`) stays off until Riffle is more than the engine half.

Zero-trace rule (DD-2) enforced structurally by `test/riffle/extrication_gate_test.exs`. Rulings log: ST0001 design.md DD-1..DD-9 (now under COMPLETED/); verbatim session logs in `intent/whiteboard/cc/.history/20260810/`. Push policy: hv authorised ("push away"); cc pushes at chunk boundaries; CI runs `mix gate` identically to local. Peer-session work landed on main this evening (hv-driven): the bin/riffle launcher rename (026310b) and credo + fleet .credo.exs (fb3e34a) -- credo cleanup of the 21 remaining baseline findings belongs to that workstream, not cc (R4b's delta: -1, zero added).

## Context for LLM

Read `intent/st/COMPLETED/ST0001/design.md` (DD-1..DD-9) and `impl.md` (as-built incl. all critic reports) before touching the engine; `intent/restart.md` carries the bounce point; the whiteboard node board carries live session state.
