---
verblock: "10 Aug 2026:v0.1: matts - Initial version"
intent_version: 2.18.0
status: WIP
slug: extricate-predicate-and-sia-from-multiplyer
created: 20260810
completed:
---

# ST0001: Extricate Predicate and SIA from Multiplyer

## Objective

Port the Predicate engine and extricate the SIA assets from Multiplyer (post-archive: `~/Devel/prj/_Archive/Multiplyer` -- a runnable repo; read-only forensics there are fine, no new work lands in its history). The engine lifts nearly as-is WITH its tests -- it is Ctx-free (zero Ctx call sites, measured 2026-08-10). SIA glue and datasource are carried over as reference material for ST0003's rewrite, not grafted verbatim.

FIRST TASK, before any porting: root-cause D2 -- `Multiplyer.Sia.process(ctx, :default_module)` yields `[]` where the pre-compiled pipeline should produce tagged items. Five characterisation tests in `test/multiplyer/sia/sia_pipeline_test.exs` pin `assert [] = results` deliberately. The verdict that matters: does the defect live in the Predicate engine (it TRAVELS with the port) or in SIA glue (it dies in ST0003's rewrite)? Ownership of this diagnosis transferred here from Multiplyer ST0042/WP-02 by owner re-sequencing (2026-08-10).

## Context

The full bill of materials, measured dependency facts, ctx-next contract table, stitch-severance notes, and defect ledger live in `intent/docs/extrication-handoff.md` -- read it first. Provenance and the complete triage record: Multiplyer ST0042 (`_Archive/Multiplyer/intent/st/ST0042/`).

## Acceptance

Acceptance Criteria and Acceptance Tests for this steel thread live in `acceptance.md` (the single source of truth). Do not restate ACs here -- see that file for the ratified completeness boundary and live status.

## Related Steel Threads

- ST0002 (ctx-next: the Bowtie waist) -- the engine port does not block on it; SIA rewrite (ST0003) needs both
- ST0003 (SIA pattern layer rewrite) -- consumes this thread's ported engine + ST0002's waist

## Context for LLM

This document represents a single steel thread - a self-contained unit of work focused on implementing a specific piece of functionality. When working with an LLM on this steel thread, start by sharing this document to provide context about what needs to be done.

### How to update this document

1. Update the status as work progresses
2. Update related documents (design.md, impl.md, etc.) as needed
3. Mark the completion date when finished

The LLM should assist with implementation details and help maintain this document as work progresses.
