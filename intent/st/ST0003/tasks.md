# Tasks - ST0003: SIA pattern layer rewrite

## Tasks

- [x] Author the acceptance contract (22 ACs across 3 WPs) before any code
- [x] Record the design: DD-1..DD-10, the architecture, and the alternatives rejected
- [x] Register every new module in MODULES.md before creating its file
- [x] WP-01: red-first tests, then `Riffle.Sia` -- staging, results, ingest, the declared metadata key
- [x] WP-01: four fences (evidence x2, no-rescue, single-transition) plus two new boundary directions
- [x] WP-01: mutation-check all eight, restore, gate
- [x] WP-02: `Riffle.Sia.Pipelines` -- the closed source vocabulary
- [x] WP-02: `Riffle.Sia.DefaultPipeline` and `priv/sia/sia.pred` -- the same definitions both ways
- [x] WP-02: the five characterisation assertions strengthened; the four that asserted nothing given outcomes
- [x] WP-02: mutation-check M9-M11; act on what M9 exposed (cache masking the file source)
- [x] WP-03: critic rounds, remediation at source, whole-tree sweep
- [x] WP-03: impl.md as-built + mutation table + critic record; bedrock updated
- [x] WP-03: close the thread

## Task Notes

The order that mattered: contract before design, design before code, tests before implementation, mutation before claiming a fence green. WP-02 broke the tests-before-implementation half of that, which is recorded in impl.md rather than glossed -- and M9 is the evidence for why it costs something.

## Dependencies

ST0001 (the ported engine) and ST0002 (the waist) both closed before this thread began. It consumes both and adds the only module that names either.
