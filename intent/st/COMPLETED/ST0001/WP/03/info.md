---
verblock: "10 Aug 2026:v0.1: matts - Initial version"
wp_id: WP-03
title: "Predicate engine port"
scope: Medium
status: Done
---

# WP-03: Predicate engine port

## Objective

Port the Predicate engine (15 files, ~5.1k LOC) and its test suite into `lib/riffle/predicate/` / `test/riffle/predicate/` per the design.md rename map. Sever stitch 1 (config-injected default-pipeline resolution, DD-1), fix D5, and land with zero source-project traces (DD-2). Discipline per DD-4 as amended (hv 2026-08-10): engine semantics port; shapes that conflict with the rule library are rewritten -- code and tests -- in layered commits, green at each step.

## Deliverables

- `Riffle.Predicate` subtree + ported test suite, green under the WP-02 gate
- AT-03.2 zero-trace gate test and AT-03.3 config-resolution tests (written red-first, per design.md approach order)
- critic-elixir advisory findings logged for a later thread (not gating)

## Acceptance

Acceptance Criteria for this work package live in the steel thread's `acceptance.md`, under the `WP-03` heading (single source of truth). Do not restate ACs here.

## Dependencies

- WP-01 (verdict may add a red-first AT to this scope)
- WP-02 (gate exists before ported code lands)
