---
verblock: "11 Aug 2026:v0.1: matts - Initial version"
wp_id: WP-02
title: "The arca_cli command surface"
scope: Small
status: Done
---

# WP-02: The arca_cli command surface

## Objective

Put an `arca_cli` command surface over the service, using the framework's own features rather than rebuilding them, and prove the commands are thin by fencing what they are allowed to name.

## Deliverables

- `Riffle.Cli.Configurator` -- `BaseConfigurator`; the one command list.
- `Riffle.Cli.Commands.SiaCommand` -- the `sia` namespace parent, help on empty.
- `Riffle.Cli.Commands.SiaRunCommand` -- `sia.run`: parse to call to render. Returns an `Arca.Cli.Ctx`, so outcome and rendering are the framework's job.
- `Riffle.Cli.Commands.SiaPipelinesCommand` -- `sia.pipelines`: report what a source defines without running it.
- **The thin-coordinator fence** -- no module under the CLI layer names an engine, waist or pattern-layer module at any depth. A command that reaches past the service takes it red. This is `IN-AG-THIN-COORD-001` stated mechanically.
- Output style reached through `Arca.Cli.Ctx.parse_style/1`; an unrecognised style is refused, not silently defaulted.

## Dependencies

- WP-01: the service module is what these commands coordinate over.

## Acceptance

Acceptance Criteria for this work package live in the steel thread's `acceptance.md`, under the `WP-02` heading (single source of truth). Do not restate ACs here.

## Dependencies

- [List any dependencies on other WPs or external factors]
