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

- (2026-08-10) ST0001 WP-03 remediation phase: mechanical port LANDED (commit 7b7f912, gate green 237 passed). critic-elixir review + test-check running on the ported tree; CRITICAL/HIGH findings get fixed per DD-4-as-amended.

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
- (2026-08-10) hv (mid-session): fresh-start flexibility -- rewrite whatever needs rewriting, code AND tests; the rewrite must be worthwhile. DD-4 amended: quality over fidelity; critic pass is remediation, not advisory; AC-03.4 added. Engine semantics still port (the asset); commits layered for reviewability.
- (2026-08-10) cc: WP-01 verdict -- D2 is SIA GLUE (sia.ex never writes cargo :results; removed deliberately in archive commit e0b5dc2a). Engine exonerated: produces correctly tagged sense->infer->act items. Nothing travels with the port. Full evidence: ST0001 design.md "D2 verdict".
- (2026-08-10) hv (mid-session 2): PFIC the ported engine -- not just critic patches. DD-7: merged with hydration consolidation into WP-04 (one loud resolver, pattern-matched heads, file-by-file, gate green each step). Correctness pins (WP-03 criticals + un-neutered tests) land first.
