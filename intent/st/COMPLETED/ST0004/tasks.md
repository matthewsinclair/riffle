# Tasks - ST0004: The service module and the CLI

## Tasks

- [x] Author the acceptance contract (26 ACs across 3 WPs) before any code
- [x] Record the design: DD-1..DD-10, and hv's ruling that the CLI is not a port
- [x] Register every new module in MODULES.md before creating its file
- [x] WP-01: `Riffle.Service` -- the way in; read rows, resolve a pipeline, stage it, report what happened
- [x] WP-01: `Riffle.Service.Csv` -- the declared user-input boundary; a width mismatch is a tagged error, never padded or truncated
- [x] WP-01: `Riffle.Service.Result` -- the typed outcome, with the summary as a projection of stage evidence
- [x] WP-02: the `arca_cli` command surface -- `sia.run` and `sia.pipelines`, using the framework's own features
- [x] WP-02: the thin-coordinator fence -- no CLI module may name an engine, waist or pattern-layer module
- [x] WP-03: the bindings -- `mix riffle.cli`, the escript, the devbin `cli` command, and `priv/sia/sample.csv`
- [x] WP-03: mutation-check M1-M10, restore, gate
- [x] WP-03: critic round, impl.md as-built, close the thread

## Task Notes

hv's ruling shaped everything: the CLI is not a port of the archived one. The service module holds the business logic and names no CLI framework; the command and the mix task are both thin coordinators over it. Recorded as DD-1..DD-5.

Two things this thread got wrong before it got them right, both in impl.md rather than glossed. The mix task was going to delegate to the service until it became clear that would mean a second argv parser; it delegates to the framework instead (DD-4). And `bin/riffle cli` was reported as working on the strength of green subcommands -- the bare invocation raised on an unset `:url`, because the intro banner reads configuration no subcommand touches. hv caught it. `cli/config_test.exs` now reads the framework's source and requires every key it fetches to be set.

M2 is the mutation worth keeping: hardcoding the stage summary left every shipped-pipeline test green, and only a four-loop pipeline caught it. That is precisely how the archived CLI shipped its defect.

## Dependencies

ST0001, ST0002 and ST0003 all closed before this thread began. The service consumes the pattern layer and nothing below it; the CLI consumes the service and nothing below that.
