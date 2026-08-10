---
node: cc
name: Control Claude
role: control
session_id: 8b09c4df-a4be-4d1c-87d9-7b8a76293477
heartbeat_at: 2026-08-10T20:58Z
status: active
focus: "ST0001 CLOSED; idle pending hv assignment (ST0002 next)"
claims: []
---

# Control Claude (cc)

## DOING

- (2026-08-10) ST0001 CLOSED -- gate 11/11, docs moved to intent/st/COMPLETED/ST0001. R4b landed (7c3c940): Dsl.Statements shared ladder, one top-level dispatch, STD surface made real (call head + expand_std). Critics: code 0C/0W on the DSL files; test-check's 1 CRITICAL exposed-and-fixed. Gate 286 green, zero warnings. Awaiting hv for ST0002.

## TODO

- ST0002 (ctx-next, Bowtie waist) -- blocked on hv assignment/plan ratification
- ST0003 (SIA rewrite) queued behind ST0002; D2 obligations recorded in ST0001 design.md

## Watch-outs

- Engine must NEVER reference the pattern layer -- resolution only via `config :riffle, :default_pipeline`; the stitch must not re-form.
- Archive (`~/Devel/_Archive/Multiplyer`) is read-only forensics: no new work lands in its history.
- No silent failures anywhere: unresolvable references raise; rescue-and-swallow forbidden.
- One resolution path (Resolver), one evaluation entry point (Loop.process), one coercion contract (Coerce), one block grammar (Dsl.Statements), one top-level dispatch -- no parallel paths.
- Zero source-project traces in lib/ + test/ -- extrication_gate_test enforces; keep it green.
- Credo is at ZERO and `mix gate` now runs `credo --strict`, so CI enforces it -- a new finding fails the gate locally and upstream. Keep it at zero rather than re-accumulating a baseline.
- Peer sessions (hv-driven) land commits on main: launcher 026310b, credo fb3e34a. Commit by explicit pathspec, never -A.

## Decisions

- (2026-08-10) All session rulings settled and recorded permanently: ST0001 design.md DD-1..DD-9, intent/wip.md, intent/restart.md. Verbatim logs archived in .history/20260810/wip.md.
- (2026-08-10) hv mid-session 3: credo added by peer sessions; cc ruled to ignore it ("I will get another Opus session to fix it") -- cc verifies only that its own commits add zero findings.
- (2026-08-10) cc R4b deviation from restart.md's accept-list design, recorded in impl.md: the completeness check is the top-level dispatch's catch-all (one home), because a head-only accept-list still silently dropped recognised-head-malformed-shape statements.
- (2026-08-10) cc: STD surface -- alias injection deleted as theatre; STD binds at body evaluation (Predicate.create/1 expand_std); .pred alias statements now reject rather than accept-and-ignore.
- (2026-08-10) hv: main is branch-protected on GitHub -- required check `gate`, strict, no force-push, no deletion, `enforce_admins: false`. Direct-to-main push policy therefore UNCHANGED (owner pushes are not constrained). Flipping enforce_admins to true would end direct pushes and require branch+PR per chunk -- deferred, not declined.
- (2026-08-10) hv/cc: no CD, deliberately. Devbin has no `release`; its `publish` opt-in (default `mix hex.publish`) stays disabled because Riffle 0.1.0 is half its intended shape until ST0002/ST0003 land. CD shape when wanted: version bump -> tag -> release.yml reusing `mix gate` -> hex publish with a HEX_API_KEY secret.
