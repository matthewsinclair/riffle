---
node: cc
name: Control Claude
role: control
session_id: 8b09c4df-a4be-4d1c-87d9-7b8a76293477
heartbeat_at: 2026-08-11T05:59Z
status: paused
focus: "All three threads CLOSED; on the bounce, reassess what's next with hv (hv's instruction, 2026-08-11)"
claims: []
---

# Control Claude (cc)

## DOING

- (paused at localfold #5, 2026-08-11) Nothing in flight. ST0003 CLOSED 22/22, joining ST0001 (11/11) and ST0002 (17/17). The extraction Riffle was created to perform is done: engine, waist, and the pattern layer that composes them. `mix gate` green -- 363 passed, zero credo findings, zero critic findings at any severity across 86 files. Globalfold complete (wip v0.8, restart v0.6, .claude/restart.md, README, treeindex, todo); head is 161d5c2, pushed to both remotes, CI green. Session archives: .history/20260810/wip.md (Sessions 1-5).

## TODO

- **On the bounce: reassess what's next, with hv** (hv's instruction, 2026-08-11). This is a decision, not a continuation -- nothing is queued and no thread is open. Bring the three candidates below rather than picking one unilaterally.
- The candidates, with reasoning in `intent/wip.md`: a second consumer (teaches the most -- every mechanism here currently has exactly one, which is the honest reason several were not built); a thin CLI (the smallest thing that makes Riffle usable by someone not writing Elixir); publishing (`mix hex.publish` is wired but deliberately off).
- Backlog needing an hv ruling: socrates on the perturbation/emission structural twins; whether the measured-surface fence should parse the handoff doc rather than transcribe it; one error vocabulary for malformed DSL text at the loader boundary (public contract change); socrates on a single definition-argument-shape recogniser in `Dsl.Statements`.
- Backlog needing a thread: Cache perf (ST0001 DD-9/M4); cache key source-qualification (the key is the predicate's *name*, so two sources defining the same name share an entry).
- Open question filed for hv: should Riffle ship a `config/` pointing `:default_pipeline` at `Riffle.Sia.DefaultPipeline`? It would make `:default_module` work out of the box and also wire the example in as everyone's default. Left unconfigured.

## Watch-outs

- **`intent/docs/bedrock.md` is bedrock**: eight commitments, seven negations, each bound to the fence that holds it. A contradiction with it is a bug in the contradicting document. Changing a commitment is argued there, never taken locally inside a WP.
- **The shape is which part may name which**: the engine names nothing, the waist names nothing, the pattern layer names both and is named by neither. Fenced in all four directions, AST-based.
- **A fence that cannot fail is not a fence.** Mutation-check every new one; give it a positive control when its discriminator would otherwise never fire. Two threads running, mutation testing has caught the *test estate* rather than the code -- a dead fence in ST0002, a cache-masked source in ST0003.
- **The evaluation cache keys on the predicate's NAME.** Two sources defining the same predicate name share one entry. Any test comparing two sources must disable the cache or it compares one source with itself.
- **A ruling is not applied until it is applied everywhere.** ST0002 struck the "reference implementation" claim from two documents and missed the README. Grep before closing.
- Source-text scanning is a weak instrument: `alias Riffle.{Ctx}` defeats it, and that form is already in the tree. Use the parsed AST or the compiled call closure.
- No silent failures: a path or name a correct program can get wrong is a tagged error; a value outside a declared vocabulary raises. Neither is ever a quiet empty result.
- `mix gate` is format + compile + test (warnings-as-errors, incl. test compile) + `credo --strict`, and CI runs the same alias. `intent critic elixir` is the headless rule-library sweep; keep both at zero.
- Zero source-project traces in lib/ + test/ -- `extrication_gate_test` enforces. `intent/` and the README are the declared exception.
- Peer sessions (hv-driven) land commits on main. Commit by explicit pathspec, never `-A`. Remotes are `local` and `upstream`; there is no `origin`.

## Decisions

- (2026-08-10) hv: Riffle is an EXAMPLE of the Bowtie pattern, not its reference implementation. Permanent record: ST0002 design.md DD-1, `intent/docs/bedrock.md`.
- (2026-08-10) hv: apply the Lamplight discipline in full -- conformance fences over example tests, spec-first per WP.
- (2026-08-10) hv: ST0002 and ST0003 scope calls ratified; run autonomously from localfold #4 to the end of what is reachable.
- (2026-08-10) cc: the Predicate engine is an inferential edge, never inside the knot. ST0003 built that edge; both directions remain fenced.
- (2026-08-10) cc: a stage is a loop (ST0003 DD-2); results in three places that must agree (DD-3); one statistic, computed as a projection (DD-4); two kinds of failure kept different (DD-8).
- (2026-08-10) All ST0003 rulings recorded permanently in `intent/st/COMPLETED/ST0003/{design,impl}.md` and `intent/docs/bedrock.md`; verbatim session logs in `.history/20260810/wip.md` (Sessions 1-5).
