---
verblock: "11 Aug 2026:v0.1: cc - Design decisions for the CLI, authored before the code"
st_id: ST0004
title: "The CLI: a thin coordinator over a service module -- design"
---

# ST0004 The CLI -- Design

The three closed threads built a library. This one gives it a way in from the command line, and in doing so becomes the **second consumer** the reassessment identified as the thing that would teach the most: every mechanism in Riffle had exactly one consumer, which is the honest reason several were never built. A CLI is what shows whether the separation is real or merely declared.

## The layering

```
bin/riffle cli ──→ mix riffle.cli ──→ Arca.Cli.main(argv)
                                            │
                            Riffle.Cli.Commands.*      thin: parse -> call -> render
                                            │
                            Riffle.Service             the service module (no CLI framework)
                                            │
                            Riffle.Sia.run/4           pattern layer
                              ├─ Riffle.Ctx.Knot       waist
                              └─ Riffle.Predicate      engine
```

Two new layers sit above the pattern layer. The rule that held the first three -- which part may name which -- extends upward unchanged, and every clause of it is a fence rather than a convention.

## DD-1 -- The service module is the seam

hv's ruling, 2026-08-11: business logic lives in a service module; the CLI and the mix task are both thin coordinators over it. `Riffle.Service.run/1` is the one entry point. It resolves a pipeline source, reads rows, runs the pattern layer, and returns a typed result.

This is the Thin Coordinator rule (`IN-AG-THIN-COORD-001`) applied at the process boundary: a command parses argv, calls the service, and renders the answer. Nothing else.

## DD-2 -- The CLI dependency is contained above the service

`arca_cli` arrives with optimus, arca_config, jason, owl and ex_prompt, and it is its own OTP application. None of that may reach the library. The engine, the waist, the pattern layer and the service all name no `Arca` module at any depth, so Riffle remains usable -- and its tests remain runnable -- by a caller that never loads the CLI framework.

Fenced. This is the clause that makes "the CLI is optional" a fact rather than an intention.

## DD-3 -- Thin-ness is a fence, not a claim

No module under `lib/riffle/cli/**` names an engine, waist or pattern-layer module at any depth. A command that reaches past the service to `Riffle.Sia` -- the shortcut that is always locally convenient -- takes the fence red.

"Thin coordinator" is otherwise a style assertion that decays the first time someone is in a hurry. Stated mechanically, it cannot.

## DD-4 -- One argv parser

The mix task delegates to `Arca.Cli.main/1`, not to `Riffle.Service` directly. Reading hv's instruction literally would put a second doorway into the service, and a second doorway needs its own argv parsing -- two parsers for one command surface, which is the Highlander violation (`IN-AG-HIGHLANDER-001`) in its most familiar form. Mix stays a doorway; arca stays the only parser. This also matches the framework's own `Mix.Tasks.Arca.Cli`.

## DD-5 -- The framework's features are used, not rebuilt

The archived layer wrapped `arca_cli` in a 1198-line local `CommandBase` and hand-rolled output formatting, error handling and command outcome. All three now exist in the framework:

| Need                      | Framework surface                        | Not built here           |
| ------------------------- | ---------------------------------------- | ------------------------ |
| Command definition        | `Arca.Cli.Command.BaseCommand`           | a local base command     |
| Registration              | `Arca.Cli.Configurator.BaseConfigurator` | a local command table    |
| Command context           | `Arca.Cli.Ctx`                           | a local ctx bridge       |
| Output styles + rendering | `Arca.Cli.Output`, `Ctx.parse_style/1`   | a local formatter        |
| Outcome / exit status     | `Ctx.outcome/1`                          | local status plumbing    |
| Help, dot-notation        | `Arca.Cli.Help`                          | local help text assembly |
| REPL                      | `repl` command                           | --                       |
| Test driving              | `Arca.Cli.Testing.CliCommandHelper`      | a local harness          |

`handle/3` returns an `Arca.Cli.Ctx`; `Arca.Cli` turns that into `{:ok, Ctx.outcome(ctx), Output.render(ctx)}`. That is the whole contract, and it is why the commands here are short.

## DD-6 -- Two context types, kept apart

`Arca.Cli.Ctx` is the _command_ context: output items, errors, cargo, style, outcome. `Riffle.Ctx` is the bowtie waist: run state that changes only through `Knot.tick/2`. They are unrelated types with the same short name, and conflating them is what produced the archived layer's `set_cargo_item` / `with_status` / `complete` sprawl through what should have been business logic.

The service returns a `Riffle.Ctx`; the command renders _from_ it into an `Arca.Cli.Ctx`. No CLI module constructs or updates a `Riffle.Ctx` -- already swept by `single_transition_fence_test`, which covers `lib/**/*.ex` minus the waist and therefore covers both new layers the moment they exist.

## DD-7 -- The summary is a projection of stage evidence

The archived command reconstructed stage identity by parsing tag prefixes -- `get_tags_with_prefix(item, "signal_")` -- into three fixed output columns. That contradicts ST0003 DD-2 (a stage _is_ a loop, and its identity is the loop's own name) and it hardcodes the sense/infer/act shape into the one place a user actually sees, which would make the README's "a pipeline with four loops runs as four stages with no code change" false at the command line.

Here the summary is `ctx.metadata[:stage_counts]`: a keyword list computed by the pattern layer as a projection of the `StageCompleted` emissions it already produced. The service passes it through; the command renders it. A four-loop pipeline whose loops are named arbitrarily summarises as four stages under those four names.

Fenced behaviourally, over a pipeline whose loop names follow no convention. This is bedrock commitment 8 -- no derived claim outlives its evidence -- reaching the surface the user reads.

## DD-8 -- Two kinds of failure, kept different

Consistent with ST0003 DD-8. A path or name that a _correct_ caller can get wrong is a tagged error in a closed vocabulary: input file absent, unreadable, carrying no data rows, malformed; pipeline source absent; pipeline name not present in the source. A value outside a declared vocabulary is a programmer error and raises.

The service resolves the pipeline _before_ it runs, so a bad source or name is a tagged error rather than a run that fails halfway. What remains inside the run is a raising predicate, which propagates unchanged.

The one rescue in the layer is at the CSV boundary and names its exception type, exactly as `Riffle.Predicate.Dsl.Loader` does for `.pred` text. The fence forbids the rescue-all -- the shape that produced D9 -- rather than the keyword, which is both provable and stricter where it matters.

## DD-9 -- The dependency is pinned

`{:arca_cli, github: "matthewsinclair/arca-cli", tag: "v0.5.0"}`, not `branch: "main"`. This project's discipline is a gate that stays green; a dependency that can change underneath a green gate defeats it. hv has hex publication of `arca_config` and `arca_cli` on the plan, at which point this becomes an ordinary version requirement and Riffle's own publication unblocks with it.

## DD-10 -- What was deliberately not built

- **Streaming.** The archived command streamed to a file with `:counters`, batch events and a million-row cap. `Riffle.Sia.run/4` is eager by contract -- it returns `{ctx, emissions}` over a materialised list -- so streaming is a change to the waist's contract, not an option on the CLI. Filed, not built.
- **Progress bars and spinners.** Machinery for a problem this does not yet have.
- **Per-stage tag attribution in output.** Which stage added which tag is derivable by diffing consecutive `StageCompleted` outputs. Nothing needs it yet, and guessing at it via tag prefixes is precisely what DD-7 forbids.
- **A datasource abstraction.** ST0003 DD-10 declined one on the grounds that there was a single consumer. There still is. `Riffle.Service.Csv` is a reader, not a layer; a second input format is when the abstraction gets earned.
- **A local `CommandBase`.** See DD-5.
