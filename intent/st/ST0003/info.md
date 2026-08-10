---
verblock: "10 Aug 2026:v0.1: matts - Initial version"
intent_version: 2.18.0
status: WIP
slug: sia-pattern-layer-rewrite
created: 20260810
completed:
---

# ST0003: SIA pattern layer rewrite

## Objective

Rewrite the SIA pattern layer (sense -> infer -> act staging over the ported Predicate engine) red-first against ctx-next. Multiplyer's glue (`sia/` -- 1.2k LOC) is reference material only: its `.pred` file loading is dead by design (returns `{:error, :invalid_pipeline_format}` unconditionally -- see handoff, D1), and its rescue-all error swallow (D9) must NOT be reproduced. The five Multiplyer characterisation tests pinned at `assert [] = results` become this thread's red-first acceptance tests, strengthened to `assert [%Item{} | _] = results`.

Scope decisions this thread owns: whether `.pred` file pipelines return (vs module-defined pipelines only, initially), and whether the CSV datasource ports or a cleaner ingest boundary replaces it.

## Context

See `intent/docs/extrication-handoff.md` for the defect ledger subset, the predicate->sia fallback stitch that must not re-form (dependency inversion: the engine never references the pattern layer), and the test-estate notes.

## Acceptance

Acceptance Criteria and Acceptance Tests for this steel thread live in `acceptance.md` (the single source of truth). Do not restate ACs here -- see that file for the ratified completeness boundary and live status.

## Related Steel Threads

- ST0001 (extrication) -- blocks this thread (needs the ported engine + D2 verdict)
- ST0002 (ctx-next) -- blocks this thread (needs the waist)

## Context for LLM

This document represents a single steel thread - a self-contained unit of work focused on implementing a specific piece of functionality. When working with an LLM on this steel thread, start by sharing this document to provide context about what needs to be done.

### How to update this document

1. Update the status as work progresses
2. Update related documents (design.md, impl.md, etc.) as needed
3. Mark the completion date when finished

The LLM should assist with implementation details and help maintain this document as work progresses.
