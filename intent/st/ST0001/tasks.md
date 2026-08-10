# Tasks - ST0001: Extricate Predicate and SIA from Multiplyer

## Tasks

### WP-01 -- D2 root-cause and verdict

- [ ] Run the five characterisation tests in the archive (read-only)
- [ ] Trace `process/4` -> `prepare_data/1` -> `load_pipeline/2` -> `execute_sia_pipeline/3`; find the empty-set step
- [ ] Classify engine-vs-glue; record verdict + file:line evidence in design.md
- [ ] If engine-side: add a red-first AT to WP-03 scope (contract amendment)

### WP-02 -- Scaffolding and CI gate

- [ ] Local gate: `mix format --check-formatted`; `mix test --warnings-as-errors` (test compilation covered)
- [ ] `.github/workflows/ci.yml` (format + compile + test, warnings-as-errors)
- [ ] Gate green on the empty skeleton

### WP-03 -- Predicate engine port

- [ ] Copy `predicate/` sources + tests (unrenamed; will not compile)
- [ ] Write AT-03.2 zero-trace gate (RED) and AT-03.3 config-resolution tests (RED)
- [ ] Mechanical rename per the design map
- [ ] Sever stitch 1 (DD-1); scrub the `dsl/macro.ex` comment
- [ ] Fix D5 arg shape
- [ ] Full suite green under the gate; ATs green
- [ ] critic-elixir advisory pass; findings logged (not gating)

## Task Notes

WP-01 is time-boxed (~2h): on overrun, record the partial trace and escalate to hv rather than stall.

## Dependencies

WP-01 precedes WP-03 (the verdict may add a red-first AT). WP-02 precedes WP-03 (the gate exists before ported code lands). WP-01 and WP-02 are independent of each other.
