---
verblock: "10 Aug 2026:v0.4: cc - WP-04 c1..c10 + R4a landed; R4b + close remaining"
---

# Work In Progress

## Current Focus

**ST0001: Extricate Predicate and SIA from Multiplyer** -- WP-01..03 DONE; WP-04 ~90% done (twelve gate-green commits 2026-08-10), R4b + close remaining.

- Resolver (DD-9) is THE resolution+hydration path; macro/loop/pipeline/registry/loader all route through it; one evaluation entry point (streams cached); STD twin dead; silent drops raise; expr tests consolidated; Coerce strict (DD-8); test/support canonical fixtures
- Critic re-runs: test-check 0 CRITICAL / 2 WARNING (fixed in R4a); code 0 CRITICAL / 6 WARNING (5 fixed in R4a; the macro/parser extraction twin remains = R4b)
- Suite 282 green; CI green on first Actions run; both remotes pushed at fold

## Active Steel Threads

- ST0001 (WIP): WP-04 R4b (shared Dsl.Statements ladder + loader top-level completeness) -> AC-04.2 verify -> `intent wp done ST0001/04`
- ST0002 (Not Started): ctx-next, the Bowtie waist
- ST0003 (Not Started): SIA pattern layer rewrite -- D2 implications recorded in ST0001 design.md (deliver results via emissions; no lying availability flag)

## Upcoming Work

- WP-04 R4b + close (see intent/restart.md for the exact order)
- Backlog (filed, unscheduled): Cache perf fix (persistent_term flag + ets counters -- DD-9/M4); socrates handoff on Macro vs DefaultPipelineConfig accessor generation; diogenes test-spec pass; cache key source-qualification (documented limitation)
- Then ST0002 kickoff (needs hv assignment/plan ratification)

## Notes

Zero-trace rule (DD-2) enforced structurally by `test/riffle/extrication_gate_test.exs`. Rulings log: ST0001 design.md DD-1..DD-9; verbatim session logs in `intent/whiteboard/cc/.history/20260810/`. Push policy: hv authorised 2026-08-10 ("push away"); cc pushes at chunk boundaries, CI runs `mix gate` identically to local.

## Context for LLM

Read ST0001's design.md (DD-1..DD-9) and impl.md (as-built incl. critic reports) before touching the engine; intent/restart.md carries the bounce-point work order; the whiteboard node board carries live session state.
