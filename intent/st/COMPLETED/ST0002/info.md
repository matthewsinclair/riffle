---
verblock: "10 Aug 2026:v0.1: matts - Initial version"
intent_version: 2.18.0
status: Completed
slug: ctx-next-the-bowtie-waist
created: 20260810
completed: 2026-08-10T22:32:48Z
---

# ST0002: ctx-next: the Bowtie waist

## Objective

Build `ctx-next`, Riffle's context waist, to the spec of The Bowtie Pattern (Sinclair, Feb 2026: Lamplight `docs/external/whitepapers/bowtie/the_bowtie_pattern.md`): typed perturbations fan in, a pure knot `f(P, S) -> (E, S')` processes them against immutable state, typed emissions fan out to registered consumers. This is a REBUILD to spec, not a port -- Multiplyer's `Ctx` (an 18-field god-struct with 76 public functions) is the pattern's earliest incarnation and is deliberately not carried over.

The minimum surface it must serve is measured, not guessed: the 24 Ctx functions the extricated code actually consumes, by call-site count, in `intent/docs/extrication-handoff.md` -- dominated by status transitions, metadata, event lifecycle (started/completed/progress), error accumulation, and input/output/cargo access. Serve that surface through the typed model (perturbations/emissions), do not replicate the bag-of-maps API shape.

## Context

Riffle is an example of the Bowtie pattern, not its reference implementation (hv ruling 2026-08-10, correcting the inherited framing). The pattern is a conceptual shape; this thread follows it because the discipline earns its keep, not to demonstrate generality. The Predicate engine (ST0001) is Ctx-free; only the SIA pattern layer (ST0003) and any datasource consume this waist.

## Acceptance

Acceptance Criteria and Acceptance Tests for this steel thread live in `acceptance.md` (the single source of truth). Do not restate ACs here -- see that file for the ratified completeness boundary and live status.

## Related Steel Threads

- ST0001 (extrication) -- supplies the measured surface + reference material
- ST0003 (SIA pattern layer rewrite) -- first real consumer of ctx-next

## Context for LLM

This document represents a single steel thread - a self-contained unit of work focused on implementing a specific piece of functionality. When working with an LLM on this steel thread, start by sharing this document to provide context about what needs to be done.

### How to update this document

1. Update the status as work progresses
2. Update related documents (design.md, impl.md, etc.) as needed
3. Mark the completion date when finished

The LLM should assist with implementation details and help maintain this document as work progresses.
