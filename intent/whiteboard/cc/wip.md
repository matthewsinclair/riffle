---
node: cc
name: Control Claude
role: control
session_id: 8b09c4df-a4be-4d1c-87d9-7b8a76293477
heartbeat_at: 2026-08-10T22:33Z
status: paused
focus: "ST0002 CLOSED (the waist); ST0003 (SIA on the waist) next, running autonomously"
claims: [ST0003]
---

# Control Claude (cc)

## DOING

- (paused at localfold #4, 2026-08-10) ST0002 CLOSED 17/17 -- ctx-next built, fenced, and recorded; `intent/docs/bedrock.md` now carries the commitments. Next on pickup: ST0003, per intent/restart.md. hv has authorised running autonomously from here to the end of what is reachable. First act: author `intent/st/ST0003/acceptance.md` (still the unfilled template) -- the close-gate is fail-by-default. Session archives: .history/20260810/wip.md.

## TODO

- ST0003 (SIA on the waist): acceptance contract -> WPs -> red-first. The five characterisation tests become ATs strengthened to `assert [%Item{} | _] = results`; results delivered via emissions (D2's obligation, no lying availability flag); D9's rescue-all must not reproduce.
- ST0003 scope calls hv already ratified: `.pred` file pipelines IN (built and green from ST0001); CSV datasource OUT, replaced by a plain ingest perturbation.
- Backlog needing an hv call: two socrates handoffs from ST0002 (perturbation/emission twins; whether the measured-surface fence parses the handoff doc); diogenes spec pass on the ctx fences; Cache perf (DD-9/M4); loader error-vocabulary unification.

## Watch-outs

- **The engine is an inferential edge, never inside the knot** (ST0002 DD-5). It is a rules engine and it is impure (ETS cache behind a GenServer). ST0003's stages evaluate predicates at the edge and feed typed results in as perturbations. Both directions are fenced -- neither half may name the other.
- `intent/docs/bedrock.md` is bedrock: a contradiction with it is a bug in the contradicting document, not a choice. Changing a commitment is argued there, never taken locally inside a WP.
- A fence that cannot fail is not a fence. Mutation-check every new one; give it a positive control when its discriminator would otherwise never fire. One of ST0002's was dead for exactly that reason.
- Source-text scanning is a weak instrument: `alias Riffle.{Ctx}` defeats it, and that form is already in the tree. Use the parsed AST or the compiled call closure.
- No silent failures: unresolvable references raise; rescue-and-swallow forbidden; every perturbation yields a real emission.
- `mix gate` is format + compile + test (warnings-as-errors, incl. test compile) + `credo --strict`, and CI runs the same alias. Keep credo at zero.
- Zero source-project traces in lib/ + test/ -- extrication_gate_test enforces; keep it green.
- Peer sessions (hv-driven) land commits on main. Commit by explicit pathspec, never -A.

## Decisions

- (2026-08-10) hv: Riffle is an EXAMPLE of the Bowtie pattern, not its reference implementation. The pattern is a conceptual idea. No mechanism exists in the waist without a Riffle consumer. Permanent record: ST0002 design.md DD-1, intent/docs/bedrock.md.
- (2026-08-10) hv: apply the Lamplight discipline in full -- conformance fences over example tests, spec-first per WP.
- (2026-08-10) hv: ST0002 acceptance contract ratified as proposed (3 WPs).
- (2026-08-10) hv: run autonomously from localfold #4 to the end of what is reachable.
- (2026-08-10) All ST0002 rulings recorded permanently in intent/st/COMPLETED/ST0002/{design,impl}.md and intent/docs/bedrock.md; verbatim session logs in .history/20260810/wip.md (Sessions 1-4).
