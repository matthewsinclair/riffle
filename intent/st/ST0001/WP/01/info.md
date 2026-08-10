---
verblock: "10 Aug 2026:v0.1: matts - Initial version"
wp_id: WP-01
title: "D2 root-cause and verdict"
scope: Small
status: Not Started
---

# WP-01: D2 root-cause and verdict

## Objective

Root-cause D2 in the archive (read-only): `Sia.process(ctx, :default_module)` yields `[]` where the pre-compiled pipeline should produce tagged items. Deliver the verdict that decides whether the Predicate port (WP-03) carries a red-first bug fix: does the defect live in the engine (travels) or in SIA glue (dies in ST0003's rewrite)?

## Deliverables

- Engine-vs-glue verdict with file:line evidence, recorded in design.md "D2 verdict"
- If engine-side: contract amendment adding the red-first AT to WP-03

## Acceptance

Acceptance Criteria for this work package live in the steel thread's `acceptance.md`, under the `WP-01` heading (single source of truth). Do not restate ACs here.

## Dependencies

- None. Precedes WP-03 (the verdict may extend its scope). Time-boxed ~2h; on overrun, record the partial trace and escalate to hv.
