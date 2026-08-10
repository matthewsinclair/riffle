# Tasks - ST0001: Extricate Predicate and SIA from Multiplyer

## Tasks

### WP-01 -- D2 root-cause and verdict

- [x] Run the five characterisation tests in the archive (read-only) -- 12 passed, pins hold
- [x] Trace `process/4` -> `prepare_data/1` -> `load_pipeline/2` -> `execute_sia_pipeline/3`; find the empty-set step -- engine produces tagged items; glue discards them
- [x] Classify engine-vs-glue; record verdict + file:line evidence in design.md -- VERDICT: glue (`sia.ex` never writes cargo `:results`; removed in `e0b5dc2a`)
- [x] If engine-side: add a red-first AT to WP-03 scope (contract amendment) -- n/a, verdict is glue-side; no contract change

### WP-02 -- Scaffolding and CI gate

- [x] Local gate: `mix gate` alias = format --check-formatted, compile --warnings-as-errors --force, test --warnings-as-errors
- [x] `.github/workflows/ci.yml` -- runs the same `mix gate` alias (Highlander: one gate definition)
- [x] Gate green on the empty skeleton (2026-08-10); placeholder hello-world replaced with honest minimal module + doctest

### WP-03 -- Predicate engine port

- [ ] Copy `predicate/` sources + tests (unrenamed; will not compile)
- [ ] Write AT-03.2 zero-trace gate (RED) and AT-03.3 config-resolution tests (RED)
- [ ] Mechanical rename per the design map
- [ ] Sever stitch 1 (DD-1); scrub the `dsl/macro.ex` comment
- [ ] Fix D5 arg shape
- [ ] Full suite green under the gate; ATs green (mechanical-port commit)
- [ ] Remediation pass: critic-elixir on ported tree; fix CRITICAL/HIGH in code + tests; strengthen weak assertions; async where safe (hv rewrite ruling; layered commits, green at each step)

## Task Notes

WP-01 is time-boxed (~2h): on overrun, record the partial trace and escalate to hv rather than stall.

## Dependencies

WP-01 precedes WP-03 (the verdict may add a red-first AT). WP-02 precedes WP-03 (the gate exists before ported code lands). WP-01 and WP-02 are independent of each other.
