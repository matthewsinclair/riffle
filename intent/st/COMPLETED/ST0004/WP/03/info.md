---
verblock: "11 Aug 2026:v0.1: matts - Initial version"
wp_id: WP-03
title: "Bindings: mix task, escript, devbin, sample"
scope: Small
status: Done
---

# WP-03: Bindings: mix task, escript, devbin, sample

## Objective

Wire the command surface to the ways a person actually reaches it, ship input that works out of the box, and correct the documents the CLI's existence falsifies.

## Deliverables

- `Mix.Tasks.Riffle.Cli` -- what `bin/riffle cli` resolves to today and fails to find. A doorway only: it names the framework entry point and nothing else, so exactly one argv parser exists in the project (design.md DD-4).
- `escript` entry in `mix.exs` -- a standalone binary running the same commands.
- `bin/.devbin/help/cli.md` -- replacing the "No authored detail yet" stub.
- `priv/sia/sample.csv` -- columns matching the shipped pipeline definitions. The archived `users.csv` does not: it carries `user_id,email,account_status,login_count` while the shipped predicates read `@login_count`, `@days_since_login`, `@account_type` and `@subscription_status`, so a run over it would tag nothing.
- README correction -- it currently states "no CLI" under Status.
- design.md / impl.md recorded; `intent critic elixir` clean at every severity.

## Dependencies

- WP-01 and WP-02: this package binds what they build.

## Acceptance

Acceptance Criteria for this work package live in the steel thread's `acceptance.md`, under the `WP-03` heading (single source of truth). Do not restate ACs here.

## Dependencies

- [List any dependencies on other WPs or external factors]
