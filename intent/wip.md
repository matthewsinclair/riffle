---
verblock: "10 Aug 2026:v0.5: cc - ST0001 CLOSED (11/11); ST0002 kickoff next, pending hv"
---

# Work In Progress

## Current Focus

**ST0001 is CLOSED** (2026-08-10, gate 11/11 satisfied; moved to `intent/st/COMPLETED/ST0001`). The Predicate engine is extricated, PFIC-transformed, and critic-clean: one resolution path (Resolver, DD-9), one evaluation entry point (Loop.process, streams cached), one coercion contract (Coerce strict, DD-8), one DSL block grammar (Dsl.Statements), one top-level dispatch whose catch-all is the completeness check, and a genuinely working STD surface (`call` head + `expand_std/1` at `Predicate.create/1` -- R4b exposed and fixed the advertised-but-dead call syntax). Suite 286 green under `mix gate`; day total fourteen gate-green engine commits.

## Active Steel Threads

- ST0002 (Not Started): ctx-next, the Bowtie waist -- needs hv assignment/plan ratification
- ST0003 (Not Started): SIA pattern layer rewrite -- D2 implications recorded in ST0001 design.md (deliver results via emissions; no lying availability flag)

## Upcoming Work

- ST0002 kickoff (pending hv)
- Backlog (filed, unscheduled): Cache perf fix (persistent_term flag + ets counters -- DD-9/M4); socrates handoff on Macro vs DefaultPipelineConfig accessor generation; socrates question on a single definition-argument-shape recogniser in Dsl.Statements (R4b critic, deferred with calibration reasoning); one error vocabulary for malformed DSL text at the loader boundary (public-shape decision); diogenes test-spec pass; cache key source-qualification (documented limitation)

## Notes

CI/CD state (2026-08-10): CI is `.github/workflows/ci.yml` on push-to-main + all PRs, running the same `mix gate` alias as local (one gate definition, two callers); green on every run today. `main` is branch-protected upstream -- required check `gate`, strict, force-push and deletion blocked, `enforce_admins: false` so the direct-to-main push policy is unchanged. There is NO CD by decision: devbin ships no `release`, and its opt-in `publish` (default `mix hex.publish`) stays off until Riffle is more than the engine half. Note also that `mix gate` does NOT run credo -- credo is a devbin-only gate (`bin/riffle test credo`), so its 21-finding baseline is unguarded by CI until that cleanup workstream zeroes it and folds it into the alias.

Zero-trace rule (DD-2) enforced structurally by `test/riffle/extrication_gate_test.exs`. Rulings log: ST0001 design.md DD-1..DD-9 (now under COMPLETED/); verbatim session logs in `intent/whiteboard/cc/.history/20260810/`. Push policy: hv authorised ("push away"); cc pushes at chunk boundaries; CI runs `mix gate` identically to local. Peer-session work landed on main this evening (hv-driven): the bin/riffle launcher rename (026310b) and credo + fleet .credo.exs (fb3e34a) -- credo cleanup of the 21 remaining baseline findings belongs to that workstream, not cc (R4b's delta: -1, zero added).

## Context for LLM

Read `intent/st/COMPLETED/ST0001/design.md` (DD-1..DD-9) and `impl.md` (as-built incl. all critic reports) before touching the engine; `intent/restart.md` carries the bounce point; the whiteboard node board carries live session state.
