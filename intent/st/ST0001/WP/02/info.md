---
verblock: "10 Aug 2026:v0.1: matts - Initial version"
wp_id: WP-02
title: "Scaffolding and CI gate"
scope: Small
status: Done
---

# WP-02: Scaffolding and CI gate

## Objective

Stand up the quality gate before any ported line lands: `mix format --check-formatted`, compile and `mix test --warnings-as-errors` with the flag covering TEST compilation, wired locally and in GitHub Actions. Green on the empty skeleton proves the gate itself.

## Deliverables

- `.github/workflows/ci.yml` (format + compile + test, warnings-as-errors)
- Green local gate run on the empty skeleton

## Acceptance

Acceptance Criteria for this work package live in the steel thread's `acceptance.md`, under the `WP-02` heading (single source of truth). Do not restate ACs here.

## Dependencies

- None. Precedes WP-03 (the gate exists before ported code lands).
