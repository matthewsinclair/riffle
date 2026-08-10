---
verblock: "10 Aug 2026:v0.2: cc - ST0001 WP-01..03 done; WP-04 chartered"
---

# Work In Progress

## Current Focus

**ST0001: Extricate Predicate and SIA from Multiplyer** -- WP-01..03 DONE 2026-08-10; WP-04 (PFIC transform + hydration consolidation, DD-7) chartered, Not Started.

- Predicate engine ported and green under `mix gate` (237 tests, warnings-as-errors incl. test compilation)
- D2 verdict: SIA glue -- results discarded after counting (`:results` cargo writes removed in archive commit e0b5dc2a); engine exonerated, nothing travelled with the port
- All 11 critic CRITICALs remediated in layered commits (R1 29eac91, R2 335a655, R3 bea85fa); structural WARNINGs dispositioned to WP-04

## Active Steel Threads

- ST0001 (WIP): WP-04 remaining -- single loud resolver, PFIC clause shapes, expr-family test consolidation, DSL coercion contract (needs hv ruling, AC-04.5)
- ST0002 (Not Started): ctx-next, the Bowtie waist
- ST0003 (Not Started): SIA pattern layer rewrite -- D2 implications recorded for it in ST0001 design.md (deliver results via emissions; no lying availability flag)

## Upcoming Work

- WP-04 execution (socrates design pass on the resolver consolidation first, per critic advisory)
- hv ruling: DSL coercion contract -- strict (garbage input never matches, full parses only) vs the archive's forgiving-zero; recommendation is strict per No Silent Errors
- hv push decision: day's commits sit on local main; first upstream push triggers CI's first Actions run

## Notes

Zero-trace rule (DD-2) is enforced structurally by `test/riffle/extrication_gate_test.exs` (runtime-assembled needle, scans lib/ + test/ wholesale). Rulings log: `intent/whiteboard/cc/wip.md` Decisions + ST0001 design.md DD-1..DD-7. Whiteboard: single node (cc); hv has no node directory yet -- rulings arrive in-session.

## Context for LLM

This document captures the current state of development. Read ST0001's design.md (decisions DD-1..DD-7, D2 verdict) and impl.md (as-built) before touching the engine; the whiteboard node board carries live session state.
