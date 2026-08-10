---
node: cc
name: Control Claude
role: control
session_id: 8b09c4df-a4be-4d1c-87d9-7b8a76293477
heartbeat_at: 2026-08-10T21:31Z
status: paused
focus: "ST0001 closed; next up ST0002 (ctx-next) then ST0003 (SIA rewrite)"
claims: []
---

# Control Claude (cc)

## DOING

- (paused at localfold #3, 2026-08-10) ST0001 CLOSED (11/11) and credo at zero inside the gate. Next on pickup: ST0002 per intent/restart.md -- author `intent/st/ST0002/acceptance.md` (still the unfilled template) and get hv's ratification BEFORE any code, then WP breakdown. ST0003 follows. Session archives: .history/20260810/wip.md.

## TODO

- ST0002 (ctx-next, the Bowtie waist): acceptance contract -> hv ratification -> WPs -> rebuild to spec (NOT a port; measured surface = 24 Ctx functions by call-site count in intent/docs/extrication-handoff.md)
- ST0003 (SIA rewrite): red-first against ctx-next; the five `assert [] = results` characterisation tests become ATs strengthened to `assert [%Item{} | _] = results`
- Backlog needing an hv call: Cache perf; two socrates handoffs; loader error-vocabulary unification; diogenes spec pass

## Watch-outs

- Engine must NEVER reference the pattern layer -- dependency inversion holds in the rebuild too; ST0003 consumes the engine, never the reverse.
- Archive (`~/Devel/_Archive/Multiplyer`) is read-only forensics: no new work lands in its history, and nothing is ported from `Ctx` -- ST0002 is a rebuild to the published spec.
- No silent failures anywhere: unresolvable references raise; rescue-and-swallow forbidden (D9 must not reproduce in ST0003).
- One resolution path (Resolver), one evaluation entry point (Loop.process), one coercion contract (Coerce), one block grammar (Dsl.Statements), one top-level dispatch -- no parallel paths.
- `mix gate` now includes `credo --strict` and CI runs the same alias: keep credo at zero rather than re-accumulating a baseline.
- Zero source-project traces in lib/ + test/ -- extrication_gate_test enforces; keep it green.
- Peer sessions (hv-driven) land commits on main. Commit by explicit pathspec, never -A.

## Decisions

- (2026-08-10) All session rulings settled and recorded permanently: ST0001 design.md DD-1..DD-9 (now under COMPLETED/), intent/wip.md, intent/restart.md. Verbatim logs archived in .history/20260810/wip.md (Sessions 1-3).
- (2026-08-10) hv: main branch-protected, `enforce_admins: false` -- direct-to-main push policy stands; flipping to true would mean branch+PR per chunk. Deferred, not declined.
- (2026-08-10) hv/cc: no CD by decision until Riffle is more than the engine half; the shape it would take is recorded in restart.md.
- (2026-08-10) hv: ST0002 then ST0003 next, and that closes the day.
