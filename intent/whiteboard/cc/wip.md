---
node: cc
name: Control Claude
role: control
session_id: 8b09c4df-a4be-4d1c-87d9-7b8a76293477
heartbeat_at: 2026-08-11T07:34Z
status: active
focus: "ST0004 CLOSED 26/26. README done. Remaining per hv: detailed docs in docs/ (would be ST0005) -- awaiting hv's go"
claims: []
---

# Control Claude (cc)

## DOING

- (2026-08-11) **ST0004 CLOSED 26/26** -- the CLI. Four threads now closed. hv's ruling: service module holds the business logic, CLI and mix task are thin coordinators over it, arca_cli used properly with its own features. `Riffle.Service.run/1` is THE way in; `sia.run` / `sia.pipelines` sit over it; `bin/riffle cli`, `mix riffle.cli` and the escript are three doorways to one parser. Gate green -- 443 passed (69 doctests, 374 tests), 756 mods/funs, zero credo, zero critic findings at any severity across 105 files. Head `bdde201`, pushed to both remotes.

## TODO

- **Remaining per hv: detailed docs in `docs/`** -- would be ST0005. hv's framing: "Once that's done, I think we're done. All that would be left would be an update to the readme and perhaps some extra, more detailed docs in docs/." README is done (WP-03). Awaiting hv's go on scope: there is no root `docs/` today, only `intent/docs/` and `design/`, so what belongs where is worth one decision before starting.
- Backlog needing an hv ruling: socrates on the perturbation/emission structural twins; whether the measured-surface fence should parse the handoff doc rather than transcribe it; one error vocabulary for malformed DSL text at the loader boundary (public contract change); socrates on a single definition-argument-shape recogniser in `Dsl.Statements`.
- Backlog needing a thread: Cache perf (ST0001 DD-9/M4); cache key source-qualification (the key is the predicate's *name*, so two sources defining the same name share an entry).
- **Publishing is blocked on arca**: `arca_cli` and `arca_config` are GitHub deps, not on hex, so `mix hex.publish` cannot take Riffle while the CLI is a runtime dependency. hv has moving them to hex on the plan; Riffle's own publication unblocks with it. The dep is pinned to `tag: "v0.5.0"` meanwhile.
- Settled, no longer open: whether Riffle ships a `config/` pointing `:default_pipeline` at the example. It ships `config/config.exs` for the CLI framework and deliberately does NOT set `:default_pipeline` -- an omitted source is a tagged error naming the three ways to fix it, and `cli/config_test.exs` pins the absence so a future change has to be argued.

## Watch-outs

- **Verifying the paths a builder exercises says nothing about the paths a new user reaches first.** ST0004: every subcommand was green and the binding was reported as working; `bin/riffle cli` with no arguments raised on an unset `:url`, because the intro banner reads config the subcommands never touch. Run the bare form, the help, and the REPL before claiming a CLI works.
- **`arca_cli` reads configuration with `fetch_env!`.** An unset key is not a missing nicety, it raises. `test/riffle/cli/config_test.exs` reads the framework's source and requires every key it fetches to be set -- if it goes red after a dep bump, add the key rather than weakening the fence.

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

- (2026-08-11) hv: the CLI is not a port. Use `arca_cli` properly and use its features; service module holds the business logic; CLI and mix task are both thin coordinators over it. "This is the architecture. Stick to it." Permanent record: ST0004 design.md DD-1..DD-5.
- (2026-08-11) cc: thin-ness is a fence, not a claim -- no CLI module may name an engine, waist or pattern-layer module (ST0004 DD-3). One argv parser: mix delegates to the framework, not to the service (DD-4).
- (2026-08-11) hv: don't worry about the git dep for now -- moving `arca_{config,cli}` to hex is on hv's plan and will resolve it later.
- (2026-08-10) hv: Riffle is an EXAMPLE of the Bowtie pattern, not its reference implementation. Permanent record: ST0002 design.md DD-1, `intent/docs/bedrock.md`.
- (2026-08-10) hv: apply the Lamplight discipline in full -- conformance fences over example tests, spec-first per WP.
- (2026-08-10) hv: ST0002 and ST0003 scope calls ratified; run autonomously from localfold #4 to the end of what is reachable.
- (2026-08-10) cc: the Predicate engine is an inferential edge, never inside the knot. ST0003 built that edge; both directions remain fenced.
- (2026-08-10) cc: a stage is a loop (ST0003 DD-2); results in three places that must agree (DD-3); one statistic, computed as a projection (DD-4); two kinds of failure kept different (DD-8).
- (2026-08-10) All ST0003 rulings recorded permanently in `intent/st/COMPLETED/ST0003/{design,impl}.md` and `intent/docs/bedrock.md`; verbatim session logs in `.history/20260810/wip.md` (Sessions 1-5).
