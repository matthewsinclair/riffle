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

## Session 4 (post-compact bounce, archived at localfold #4)

### DOING (completed)

- hv ruling at kickoff, correcting an inherited premise: Riffle is an EXAMPLE of the Bowtie pattern, not its reference implementation. The claim came from the Multiplyer triage session and sat in ST0002 info.md + the extrication handoff; it had been read as a requirement and steered the first ST0002 design toward a generic framework. Struck from both (handoff carries a dated correction, not a silent deletion). Second hv ruling: apply the Lamplight discipline in full -- which restored three things the first correction had over-cut (closed catalog registries, the god-object refusal as architecture, conformance fences as the AT form).
- Read the Lamplight corpus rather than reconstructing it: the Bowtie whitepaper, 210-bowtie, 000-bedrock, 510-not-list, 530-hard-rules, 230-perturbation-emission, 430-testing.
- ST0002 acceptance contract authored and ratified; 3 WPs; ST0002 CLOSED (gate 17/17), docs at intent/st/COMPLETED/ST0002/.
- WP-01 02d74dd: Riffle.Ctx typed composite root (6 slots, ONE declared overlay, reads-only), two closed catalogs, 20 typed structs.
- WP-02 8df5972: Riffle.Ctx.Knot.tick/2 -- pure, total, multi-clause, one delivery-floor funnel, full stream unconditionally.
- WP-03: measured-surface fence (24 capabilities, both directions), intent/docs/bedrock.md, and two rounds of critic remediation.

### Findings worth carrying forward

- A fence of mine was DEAD: the Erlang remote-type form carries three list elements, my pattern matched two, so the DD-6 accumulator check recognised nothing and had been unfalsifiable since written. Caught by the second critic round, not by me. Two fences now carry positive controls; every fence in the thread was mutation-checked.
- A source-text fence is defeatable by `alias Riffle.{Ctx}` -- and that brace form is already in the engine's own files. Boundary fence now walks the parsed AST.
- The Elixir type checker is doing real work here: it proved the delivery floor's empty-result clause unreachable and both registries non-empty, which deleted code and two redundant guards. Under `mix gate` (--warnings-as-errors) those proofs fail the build, which is stronger than the runtime guards they replaced.

### Decisions this session

- hv: Riffle is an example of the pattern, not its reference implementation (DD-1). No mechanism exists in the waist without a Riffle consumer.
- hv: the Lamplight discipline applies in full -- fences over example tests, spec-first per WP.
- cc (DD-5): the Predicate engine is an INFERENTIAL EDGE, never inside the knot. It is a rules engine (inference) and concretely impure (ETS cache behind a GenServer). Both directions fenced. This shapes ST0003 more than anything else in ST0002.
- cc (DD-4): multi-clause dispatch, not a subscriber routing table -- trade-off named, delivery-floor fence covers it.
- cc: filed for hv -- socrates on the perturbation/emission structural twins (7 of 10 pairs), socrates on whether the measured-surface fence should parse the handoff doc, diogenes spec pass on the seven fence files.

## Session 5 (post-compact bounce; ST0003 run autonomously to the end of the queue)

### DOING (completed)

- ST0003 acceptance contract authored first, before any code (22 ACs across 3 WPs), shaped by three things settled in advance: the D2 root cause from ST0001, bedrock commitment 6, and hv's ratified scope calls (`.pred` in, CSV datasource out).
- WP-01 a92f01d: `Riffle.Sia` -- the staged edge. A stage IS a loop; the pipeline's loop sequence is the staging and a stage's identity is the loop's own name, so sense/infer/act is what a definition file says rather than a shape the runner imposes.
- WP-01 fences: results agree in three places; every derived fact arrives with its evidence; no rescue/catch/after in the layer (AST, positive controls for both forms); the knot is the only transition (both spellings of update syntax); and two new boundary directions -- neither the engine nor the waist may name the layer.
- `Riffle.WaistHelpers` became `Riffle.FenceHelpers` and the boundary fence moved from `test/riffle/ctx/` to `test/riffle/`: both were project-level despite their names, and a second helper module for the layer's fences would have duplicated the AST walk that consolidation exists to prevent.
- WP-02 2b674c2: the closed source vocabulary (`%Pipeline{}`, `{:module,_}`, `{:file,_}`, `:default_module`), `Riffle.Sia.DefaultPipeline` and `priv/sia/sia.pred` carrying the same definitions both ways.
- The nine inherited tests now assert something. The five pinned at `assert [] = results` pin the concrete surviving rows and their tags -- two of four through main, three through sense, two through infer. The four that asserted nothing assert concrete outcomes.
- WP-03: critic rounds, remediation, bedrock, and close. ST0003 CLOSED (gate 22/22), docs at `intent/st/COMPLETED/ST0003/`.
- Globalfold: `intent/wip.md` v0.8, `intent/restart.md` v0.6, `.claude/restart.md` written, treeindex refreshed over lib/ and test/, `intent todo update`, README rewritten.

### Findings worth carrying forward

- **Mutation testing caught the test estate, not the code -- for the second thread running.** M9 (drift the `.pred` file from its module twin) should have taken four tests red and took one. The evaluation cache keys on the predicate's *name*, and the file and the module share every name, so the first run warmed the cache and every later run answered from that one entry whichever source it came from. The three "from a file" tests were proving the file parses, not that it works. Characterisation suite now runs with the cache off; the same mutation takes four red.
- **ST0002's correction of the "reference implementation" claim missed the README** -- the most public document in the repo kept the struck sentence for a day. A ruling is not applied until it is applied everywhere; grep for it before closing.
- **A whole-tree critic sweep at the lowest severity found seven inherited CRITICALs** in files ST0003 never touched (`assert is_map(pipeline)` over the ST0001 port). Fixed out of scope and deliberately: closing a thread whose subject is assertions that assert nothing, while leaving seven in the tree, would be incoherent.
- **WP-02 was not written red-first** and that is recorded in impl.md rather than glossed. The mutation checks stand in for the red phase, and M9 is the evidence that the substitution is not free.

### Decisions this session

- cc (DD-2): a stage is a loop. No stage registry, no behaviour, no tag-prefix convention -- the layer would otherwise parse names it does not own and break silently for any pipeline that had not adopted the convention.
- cc (DD-3/DD-4): results in three places that must agree, and the one recorded statistic is a projection of emitted facts rather than a parallel tally. This is the anti-D2 shape, and `results_available` has no way back in.
- cc (DD-7): `ctx.input` holds the ingested items, not the raw rows, so a run replays from `ctx.input` alone without depending on an unrecorded conversion.
- cc (DD-8): two kinds of failure, kept deliberately different. A path or a name a correct program can get wrong at runtime is a tagged error that fails the run as a typed signal; a value outside a declared vocabulary raises.
- cc: bedrock gains commitment 8 (no derived claim outlives its evidence), commitments 6 and 7 extended, two negations added.
- cc: filed for hv -- whether Riffle should ship a `config/` pointing `:default_pipeline` at the example module. Left unconfigured, because wiring the example in as everyone's default is the framework smell the project has been avoiding.
