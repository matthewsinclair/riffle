---
node: cc
name: Control Claude
role: control
session_id: 8b09c4df-a4be-4d1c-87d9-7b8a76293477
heartbeat_at: 2026-08-10T18:14Z
status: paused
focus: "ST0001: D2 root-cause verdict, then Predicate engine port"
claims: [ST0001]
---

# Control Claude (cc)

## DOING

- (paused at localfold 2026-08-10) ST0001 WP-01..03 DONE, WP-04 chartered. Next on pickup: WP-04 (socrates design pass first). Session archive: .history/20260810/wip.md.

## TODO

- WP-04 (Not Started): socrates design pass -> single resolver -> PFIC shapes -> expr-family test consolidation -> coercion module (after hv ruling, AC-04.5) -> critic re-run clean
- Awaiting hv: coercion ruling (strict vs forgiving-zero; cc recommends strict), push decision
- ST0002 / ST0003 queued behind ST0001 close

## Watch-outs

- Engine must NEVER reference the pattern layer -- resolution only via `config :riffle, :default_pipeline`; the stitch must not re-form.
- Archive (`~/Devel/_Archive/Multiplyer`) is read-only forensics: no new work lands in its history.
- No silent failures anywhere: unresolvable references raise; rescue-and-swallow forbidden (D9 shape).
- Warnings-as-errors covers TEST compilation; `mix gate` green before every commit.
- Zero source-project traces in lib/ + test/ -- extrication_gate_test enforces; keep it green.

## Decisions

- (2026-08-10) All session rulings settled and recorded permanently: ST0001 design.md DD-1..DD-7 (+ D2 verdict), intent/wip.md, intent/restart.md. Verbatim log archived in .history/20260810/wip.md.
