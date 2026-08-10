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

## Session 2 (post-compact bounce, archived at localfold #2)

### DOING (completed)

- hv rulings applied at pickup: coercion STRICT (DD-8; :loose only-if-trivial -> assessed, deferred), push AUTHORISED. First upstream push fired CI's first Actions run -- green, 23s.
- WP-04 c1..c10 (all gate-green): Resolver + 27 red-first tests (5acf8e8); macro reroute (4fdbb66); one evaluation entry point, streams cached, AT-04.3 red-first (ae19111); Pipeline 6-clause maze -> 2 clauses (4c88826); Registry tagged Resolver calls, lossy callable dead (dcc43c0); Loader dependency-ordered resolution, nil-entries dead (8168ea0); STD twin dead (5e196fb); in-block silent drops raise (682824f); expr family 5 files -> 1 (c0d80fa); Coerce strict + CoercionError no-match boundary (577d4f5).
- Critic re-runs: test-check 0C/2W; code 0C/6W. R4a (d8cac87): test/support (CacheHelpers, DslFixtures), DefaultPipelineConfig canonical-map membership (reflection leak was a REAL defect exposed by the new exhaustive pin), Evaluator operator layer Coerce-complete (to_text; missing fields never glide-match; logical operands through the enumeration), within_last_days construction-bound. 282 green.

### Decisions this session

- cc (DD-9, socrates-reviewed): resolver design as recorded in design.md.
- cc: :loose coercion mode deferred (not the trivial default hv conditioned it on) -- recorded in DD-8.
- cc: R4b (extraction-ladder dedup + loader top-level completeness) split to next session at hv's fold call.

## Session 3 (post-compact bounce, archived at localfold #3)

### DOING (completed)

- WP-04 R4b (7c3c940): `Dsl.Statements` as THE block grammar (macro + parser twins and their eight dead expr clauses gone); `Parser.extract_definitions!/1` as one top-level dispatch whose catch-all IS the completeness check (deliberate deviation from restart.md's accept-list design, which would still have dropped recognised-head-malformed statements); loader thinned to parse -> extract. Critics: code 0C/0W on the four DSL files; test-check found 1 CRITICAL -- the STD-alias test pinned parse-level fields only and passed with the alias injection deleted.
- That CRITICAL exposed a real defect: the advertised `call &STD.Boolean.is_true/1, [...]` syntax had NO handler (`undefined function call/2`; the archive's always-false catch-all had swallowed it), and the loader's alias-injection prelude was theatre since parsing never resolves aliases. `Predicate.create/1` gained the `{:call, ...}` head and `expand_std/1` (pure AST prewalk; eval-env alias options are deprecated on 1.20); injection deleted.
- ST0001 CLOSED: `intent wp done ST0001/04` (5/5), `intent st done ST0001` (11/11), docs moved to `intent/st/COMPLETED/ST0001/`.
- Infra (hv-directed): branch protection on main; CI/CD posture recorded; credo taken from a 21-finding baseline to ZERO (all fixed at source, none suppressed -- three complexity findings were duplication in disguise) and `credo --strict` folded into `mix gate` so CI enforces it. 286 tests green throughout; `bin/riffle test all` green end to end.

### Decisions this session

- hv: credo initially cc's to ignore ("another Opus session will fix it"), then reassigned to cc on the "still not pristine" call -- cc fixed all 21 and put credo in the gate.
- hv: main branch-protected with `enforce_admins: false`, so the direct-to-main push policy stands; GitHub logs each direct push as a bypass. Flipping to true (branch+PR per chunk) deferred, not declined.
- hv/cc: no CD by decision -- devbin has no `release`; its `publish` opt-in stays off while Riffle is the engine half of a library whose pattern layer is unwritten.
- hv: next session does ST0002 then ST0003, and that closes the day.
