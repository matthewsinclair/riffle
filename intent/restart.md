---
verblock: "10 Aug 2026:v0.1: cc - Restart context after ST0001 WP-01..03"
---

# Restart Context

## Where things stand (2026-08-10)

ST0001 WP-01..03 DONE through their acceptance gates; WP-04 chartered (Not Started). Suite: 237 green under `mix gate` (format + strict compile + strict test). Nine commits on local main, unpushed (hv pushes upstream; first push triggers CI's first Actions run).

## Next unit of work

WP-04: PFIC transform + hydration consolidation (DD-7). Order: socrates design pass on the single resolver -> resolver module -> route pipeline.ex / loop.ex / registry.ex / loader.ex / macro layer through it -> one evaluation entry point for Loop process+filter (streams currently bypass the cache) -> STD twin removal -> expr-family test consolidation -> coercion module (BLOCKED on hv ruling, AC-04.5) -> critic re-run to zero CRITICAL / zero Highlander+PFIC WARNINGs.

## Open hv decisions

1. DSL coercion contract (AC-04.5): strict (garbage input never matches; full parses only) vs the archive's forgiving-zero. cc recommends strict per No Silent Errors.
2. Push to upstream: when a chunk is public-worthy.

## Read before touching the engine

- `intent/st/ST0001/design.md` -- DD-1..DD-7 + the D2 verdict
- `intent/st/ST0001/impl.md` -- as-built record incl. the three remediation layers
- `intent/st/ST0001/acceptance.md` -- live AC/AT map (WP-04 section is the open work)
- `intent/whiteboard/cc/wip.md` -- live node board (paused at localfold)
- `intent/docs/extrication-handoff.md` -- original charter (bill of materials, defect ledger)

## Invariants (do not regress)

- Zero source-project traces in `lib/` + `test/` -- `test/riffle/extrication_gate_test.exs` enforces structurally
- The engine never names a pattern-layer module -- resolution via `config :riffle, :default_pipeline`; unresolvable references raise `UnresolvedPredicateError`
- `mix gate` green before every commit; warnings-as-errors covers test compilation
- Archive (`~/Devel/_Archive/Multiplyer`) is read-only forensics
