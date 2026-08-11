---
verblock: "11 Aug 2026:v0.1: matts - Initial version"
wp_id: WP-01
title: "The service module and its input"
scope: Small
status: Done
---

# WP-01: The service module and its input

## Objective

Build `Riffle.Service` -- the one entry point through which every caller reaches the system -- and the CSV reading it needs. The service knows nothing of any CLI framework, so the library stays usable, and its tests stay runnable, by a caller that never loads one.

## Deliverables

- `Riffle.Service` -- `run/1`: resolve a pipeline source, read rows, run the pattern layer, return a typed result. Closed error vocabulary; the pipeline is resolved *before* the run so a bad source or name is a tagged error rather than a run that fails halfway.
- `Riffle.Service.Result` -- pipeline, input count, output count, per-stage summary, plus the run context and emissions for a caller that wants the full evidence.
- `Riffle.Service.Csv` -- header row to field maps. The declared user-input boundary: a parse failure becomes a tagged error, and the single `rescue` in the layer names its exception type.
- **The stage-agnosticism fence** -- the summary names exactly the loops the pipeline declares, by their own names, proven over a four-loop pipeline whose names follow no convention. This is the fence that makes the archived layer's tag-prefix parsing impossible to reintroduce.
- Boundary fence extension: the service names no CLI-framework module at any depth.
- No-rescue fence over the service layer: no `rescue`-all, no bare `catch`/`after`.

## Acceptance

Acceptance Criteria for this work package live in the steel thread's `acceptance.md`, under the `WP-01` heading (single source of truth). Do not restate ACs here.

## Dependencies

- [List any dependencies on other WPs or external factors]
