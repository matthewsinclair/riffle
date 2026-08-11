---
verblock: "11 Aug 2026:v0.1: matts - Initial version"
intent_version: 2.18.0
status: WIP
slug: the-cli-a-thin-coordinator-over-a-service-module
created: 20260811
completed:
---

# ST0004: The CLI: a thin coordinator over a service module

## Objective

Give Riffle a command line: run a SIA pipeline against supplied data with supplied parameters. The business logic lives in a service module; the CLI and the mix task are both thin coordinators over it, and thin-ness is enforced by a fence rather than asserted in prose.

## Context

The three closed threads built a library with no way in from a shell. `bin/riffle cli` resolves to a `riffle.cli` mix task that does not exist, so the devbin launcher reports a missing task rather than a missing feature.

This thread is also the **second consumer** the end-of-extraction reassessment identified as the thing that would teach the most. Every mechanism in Riffle has had exactly one consumer, which is the honest reason several were never built -- no datasource layer, no fan-out registry, no results store. A second consumer is what shows whether the separation between engine, waist and pattern layer is real or merely declared, and it is what forces the first genuinely new surface since ST0003: reading a file of rows.

Two rulings shape it. **hv, 2026-08-11:** use `arca_cli` properly, and use its features -- the archived layer wrapped it in a 1198-line local `CommandBase` and hand-rolled formatting, error handling and command outcome that the framework already provides. **hv, 2026-08-11:** service module at the centre, CLI and mix task thin over it. "This is the architecture. Stick to it."

The archived CLI is forensics, not a template. One thing in it is a defect this thread exists to make impossible: it reconstructed stage identity by parsing `signal_` / `inference_` / `action_` tag prefixes into three fixed output columns, which contradicts ST0003 DD-2 -- a stage *is* a loop, and its identity is the loop's own name -- and would make the README's "a pipeline with four loops runs as four stages with no code change" false at the command line. See design.md DD-7.

## Acceptance

Acceptance Criteria and Acceptance Tests for this steel thread live in `acceptance.md` (the single source of truth). Do not restate ACs here -- see that file for the ratified completeness boundary and live status.

## Related Steel Threads

- **ST0003** (the SIA pattern layer) -- supplies `Riffle.Sia.run/4` and `Riffle.Sia.Pipelines`, the surfaces the service coordinates over. DD-2 (a stage is a loop) is the commitment DD-7 here carries to the command line; DD-10 declined a datasource layer on single-consumer grounds, and this thread is the second consumer that revisits it.
- **ST0002** (the Bowtie waist) -- `Riffle.Ctx` changes only through the knot. The CLI layer inherits `single_transition_fence_test` automatically, and `Arca.Cli.Ctx` must not be confused with it (design.md DD-6).
- **ST0001** (the Predicate engine) -- `Riffle.Predicate.Dsl.Loader` is the precedent for a user-input boundary that converts raises into tagged errors, which is how the CSV reader is scoped (design.md DD-8).

## Context for LLM

This document represents a single steel thread - a self-contained unit of work focused on implementing a specific piece of functionality. When working with an LLM on this steel thread, start by sharing this document to provide context about what needs to be done.

### How to update this document

1. Update the status as work progresses
2. Update related documents (design.md, impl.md, etc.) as needed
3. Mark the completion date when finished

The LLM should assist with implementation details and help maintain this document as work progresses.
