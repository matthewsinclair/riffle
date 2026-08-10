---
node: cc
name: Control Claude
role: control
session_id: 8b09c4df-a4be-4d1c-87d9-7b8a76293477
heartbeat_at: 2026-08-10T18:21Z
status: active
focus: "ST0001 WP-04: PFIC transform + hydration consolidation"
claims: [ST0001]
---

# Control Claude (cc)

## DOING

- WP-04 IN PROGRESS (post-compact pickup 2026-08-10): socrates design pass on the single resolver, then red-first resolver build. Session archive: .history/20260810/wip.md.

## TODO

- WP-04 remaining: resolver -> route call sites -> one evaluation entry point -> STD twin removal -> expr-family test consolidation -> coercion module (strict, hv-ruled) -> critic re-run clean
- ST0002 / ST0003 queued behind ST0001 close

## Watch-outs

- Engine must NEVER reference the pattern layer -- resolution only via `config :riffle, :default_pipeline`; the stitch must not re-form.
- Archive (`~/Devel/_Archive/Multiplyer`) is read-only forensics: no new work lands in its history.
- No silent failures anywhere: unresolvable references raise; rescue-and-swallow forbidden (D9 shape).
- Warnings-as-errors covers TEST compilation; `mix gate` green before every commit.
- Zero source-project traces in lib/ + test/ -- extrication_gate_test enforces; keep it green.

## Decisions

- (2026-08-10) All session rulings settled and recorded permanently: ST0001 design.md DD-1..DD-7 (+ D2 verdict), intent/wip.md, intent/restart.md. Verbatim log archived in .history/20260810/wip.md.
- (2026-08-10) hv post-compact: coercion contract STRICT by default (`:loose` param only if trivially cheap) -- AC-04.5 unblocked, recorded as DD-8. Push AUTHORISED ("push away") -- first upstream push today fires CI's first Actions run (DD-6 note).
