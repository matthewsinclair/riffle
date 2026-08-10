# cc history -- 2026-08-10 (archived at localfold)

## DOING (completed this session)

- First pickup + orientation (handoff, ST0001/2/3, archive recon); day plan presented and ratified with amendments.
- WP-01 D2 root-cause: verdict SIA glue (sia.ex never writes cargo :results; removed deliberately in archive commit e0b5dc2a). Engine exonerated -- produces correctly tagged sense->infer->act items. Evidence: ST0001 design.md "D2 verdict".
- WP-02 gate: `mix gate` alias (format + compile + test, warnings-as-errors incl. test compile), CI workflow runs the same alias. Green on skeleton.
- WP-03 port: engine + tests + fixtures across, zero source-project traces (grep-gated), stitch 1 severed (config-injected default pipeline), D5 fixed; mechanical-port commit 7b7f912.
- WP-03 remediation (all 11 critic CRITICALs): R1 29eac91 (exact cache keys, loud create/1, registry state-resolution, date raise, config probe), R2 335a655 (hydrate-at-generation; four neutered filtering tests un-neutered with exact pins), R3 bea85fa (Cache.reset_stats/config API, tmp_dir fixtures, async registry suite). Gate 237 green at every layer.
- WP-03 closed (gate 4/4); WP-04 chartered; fold commit 894edd0.

## Decisions (settled; permanent record in ST0001 design.md DD-1..DD-7 + intent/wip.md)

- hv: ST0001 acceptance contract RATIFIED with amendments.
- hv: NO reference-material carry-over -- SIA/datasource read in archive only. WP-04 (original) dropped.
- hv: zero source-project references in Riffle code -- port then act as if the source never existed (DD-2; scope boundary: intent/ record + README stay).
- hv: push policy -- local commits; hv pushes upstream when public-worthy (DD-6).
- hv (mid-session): fresh-start flexibility -- rewrite whatever needs rewriting, code AND tests (DD-4 amended); critic pass is remediation; AC-03.4 added.
- hv (mid-session 2): PFIC the ported engine -- merged with hydration consolidation as WP-04 (DD-7).
- cc: WP-01 verdict as above; D2 dies in ST0003's rewrite, delivery-of-results becomes its AT contract.
