---
node: cc
name: Control Claude
role: control
session_id: 8b09c4df-a4be-4d1c-87d9-7b8a76293477
heartbeat_at: 2026-08-11T08:41Z
status: paused
focus: "ST0005 WP-01 (moduledocs) DONE. On the bounce: WP-02, ex_doc + README (hv's instruction, 2026-08-11)"
claims: []
---

# Control Claude (cc)

## DOING

- (paused at localfold #6, 2026-08-11) **ST0005 WP-01 DONE** -- the moduledoc pass, 6/6 ACs. Four threads closed (ST0001..ST0004); ST0005 is open with WP-02 and WP-03 to go. Gate green -- 475 passed (90 doctests, 385 tests), 776 mods/funs, zero credo, zero critic findings at any severity across 107 files. Head `0431793`, pushed to both remotes.

## TODO

- **On the bounce: ST0005 WP-02 -- ex_doc and the README** (hv's instruction, 2026-08-11). Wire `ex_doc` dev-only, group the reference by the five layers rather than 61 alphabetical modules, and make the README route to the language reference, the API and the architecture. ACs are AC-02.1..3 in `intent/st/ST0005/acceptance.md`; all three are non-test with evidence inline.
- Then **WP-03 -- `docs/pred-language.md`** with two fences: every `.pred` snippet in it parses, and every public standard-library predicate is covered. The surface it has to cover, measured: 3 definition forms, 28 expression forms in `Dsl.Evaluator`, 25 standard-library predicates across Text/Numeric/Boolean/Collection/Date. `Riffle.DocHelpers` (test/support) already carries the doc walks these will reuse.
- Backlog needing an hv ruling: socrates on the perturbation/emission structural twins; whether the measured-surface fence should parse the handoff doc rather than transcribe it; one error vocabulary for malformed DSL text at the loader boundary (public contract change); socrates on a single definition-argument-shape recogniser in `Dsl.Statements`.
- Backlog needing a thread: Cache perf (ST0001 DD-9/M4); cache key source-qualification (the key is the predicate's *name*, so two sources defining the same name share an entry).
- **Publishing is blocked on arca**: `arca_cli` and `arca_config` are GitHub deps, not on hex, so `mix hex.publish` cannot take Riffle while the CLI is a runtime dependency. hv has moving them to hex on the plan; Riffle's own publication unblocks with it. The dep is pinned to `tag: "v0.5.0"` meanwhile.

## Watch-outs

- **An `iex>` line that no `doctest` declaration picks up is a claim, not an example.** ST0005 found five such modules, 44 lines, three of them wrong -- including examples that did not compile. `doc_conformance_test.exs` now fences it. When adding examples, add the declaration in the same edit.
- **The `@field` shorthand needs a bare `@name` with no hygiene context.** It reaches the evaluator that way from `.pred` text and from `Riffle.Predicate.Dsl.Evaluator.parse/1`'s string clause. `quote(do: @field)` inside a module stamps that module as the context and the expression is refused. Documented examples must use the string form.
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

- (2026-08-11) hv: do a deep moduledoc pass -- richness AND agreement with the as-written code -- BEFORE writing anything in `docs/`. Vindicated: the root moduledoc taught a model the architecture refutes, and 44 lines of examples had never run. Permanent record: ST0005 impl.md.
- (2026-08-11) cc, ratified by hv: `docs/` earns exactly one file (the `.pred` language reference) plus `ex_doc`; `docs/cli.md` and `docs/architecture.md` are NOT written because devbin help + `--help` and `intent/docs/bedrock.md` already own them. Highlander applies to documentation.
- (2026-08-11) hv: the CLI is not a port. Use `arca_cli` properly and use its features; service module holds the business logic; CLI and mix task are both thin coordinators over it. "This is the architecture. Stick to it." Permanent record: ST0004 design.md DD-1..DD-5.
- (2026-08-11) cc: thin-ness is a fence, not a claim -- no CLI module may name an engine, waist or pattern-layer module (ST0004 DD-3). One argv parser: mix delegates to the framework, not to the service (DD-4).
- (2026-08-11) hv: don't worry about the git dep for now -- moving `arca_{config,cli}` to hex is on hv's plan and will resolve it later.
- (2026-08-10) hv: Riffle is an EXAMPLE of the Bowtie pattern, not its reference implementation. Permanent record: ST0002 design.md DD-1, `intent/docs/bedrock.md`.
- (2026-08-10) hv: apply the Lamplight discipline in full -- conformance fences over example tests, spec-first per WP.
- (2026-08-10) hv: ST0002 and ST0003 scope calls ratified; run autonomously from localfold #4 to the end of what is reachable.
- (2026-08-10) cc: the Predicate engine is an inferential edge, never inside the knot. ST0003 built that edge; both directions remain fenced.
- (2026-08-10) cc: a stage is a loop (ST0003 DD-2); results in three places that must agree (DD-3); one statistic, computed as a projection (DD-4); two kinds of failure kept different (DD-8).
- (2026-08-10) All ST0003 rulings recorded permanently in `intent/st/COMPLETED/ST0003/{design,impl}.md` and `intent/docs/bedrock.md`; verbatim session logs in `.history/20260810/wip.md` (Sessions 1-5).
