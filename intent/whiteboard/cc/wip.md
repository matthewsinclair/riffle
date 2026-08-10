---
node: cc
name: Control Claude
role: control
session_id: 8b09c4df-a4be-4d1c-87d9-7b8a76293477
heartbeat_at: 2026-08-10T16:42Z
status: active
focus: "ST0001: D2 root-cause verdict, then Predicate engine port"
claims: [ST0001]
---

# Control Claude (cc)

## DOING

- (2026-08-10) First pickup done. Orientation complete (handoff + ST0001/2/3 + archive recon). Day plan for ST0001 presented to hv -- awaiting go.

## TODO

- WP-01: D2 root-cause in archive (read-only) -> engine-vs-glue verdict recorded in ST0001
- WP-02: `intent lang init elixir` + CI gate (format, compile + test under warnings-as-errors)
- WP-03: Port predicate/ + tests -> lib/riffle/predicate; sever stitch 1 (config-injected default pipeline); fix D5; suite green; zero source-project traces
- Fold: ST0001 docs as-built, acceptance map, intent/wip.md, todo update, clean commits

## Watch-outs

- Engine must NEVER reference the pattern layer -- stitch 1 (predicate -> Sia.DefaultPipeline fallback) must not re-form in Riffle.
- Archive (`~/Devel/_Archive/Multiplyer`) is read-only forensics: no new work lands in its history.
- D9 rescue-all error swallow must not be reproduced anywhere in Riffle (No Silent Errors).
- Warnings-as-errors covers TEST compilation too, from day one (D5 class).

## Decisions

- (2026-08-10) hv: ST0001 acceptance contract RATIFIED (with amendments below).
- (2026-08-10) hv: NO reference-material carry-over -- SIA/datasource stay in the archive, read in place only. WP-04 dropped.
- (2026-08-10) hv: zero references to the source project ANYWHERE in Riffle code -- port then act as if it never existed. AC-03.2 covers lib/ + test/ via grep-gate. cc scope note: intent/ extrication record + README status para stay (hv-authored), pending explicit hv say-so.
- (2026-08-10) hv: push policy -- commit locally as needed; hv pushes upstream when a chunk is public-worthy (fewer CI triggers = lower cost). cc does not push unprompted.
- (2026-08-10) cc: port discipline -- nearly-as-is, no opportunistic refactors; critic-elixir advisory pass at end logs findings for a later thread, does not gate ST0001.
