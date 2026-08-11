---
verblock: "11 Aug 2026:v0.1: cc - As-built, mutation table, critic rounds"
st_id: ST0004
title: "The CLI: a thin coordinator over a service module -- implementation"
---

# ST0004 The CLI -- Implementation

## As-built

```
bin/riffle cli ──→ mix riffle.cli ──→ Arca.Cli.main(argv) ──→ Riffle.Cli.Commands.*
_build/escript/riffle ──────────────↗                              │
                                                          Riffle.Service
                                                                   │
                                                          Riffle.Sia.run/4
```

Three doorways, one parser. `bin/riffle cli`, `mix riffle.cli` and the escript all enter `Arca.Cli.main/1`; none of them parses arguments itself and none reaches `Riffle.Service` directly.

| Module                                    | What it is                                                       |
| ----------------------------------------- | ---------------------------------------------------------------- |
| `Riffle.Service`                          | `run/1`, `pipelines/1`, `source/1`, `message/1`. THE way in      |
| `Riffle.Service.Result`                   | pipeline, input/output counts, per-stage summary, ctx, emissions |
| `Riffle.Service.Csv`                      | header row to field maps; the declared user-input boundary       |
| `Riffle.Cli.Configurator`                 | the one command list                                             |
| `Riffle.Cli.Commands.SiaCommand`          | the `sia` namespace parent                                       |
| `Riffle.Cli.Commands.SiaRunCommand`       | `sia.run`                                                        |
| `Riffle.Cli.Commands.SiaPipelinesCommand` | `sia.pipelines`                                                  |
| `Mix.Tasks.Riffle.Cli`                    | the mix doorway; names no Riffle module at all                   |

Added to an existing module: `Riffle.Sia.Pipelines.names/1`, beside `fetch/2`, sharing its file-loading path rather than growing a second copy of it. Listing the pipelines a source defines _is_ source resolution, so it belongs in the module that owns that concern.

## What the framework does, and is therefore not written here

`handle/3` returns an `Arca.Cli.Ctx`; `Arca.Cli` turns that into `{:ok, Ctx.outcome(ctx), Output.render(ctx)}`. Command outcome, output rendering, the ansi/plain/json/dump style vocabulary, tty detection, help, dot-notation grouping, the REPL, history and `cfg.*` are all the framework's. The archived layer wrapped the same framework in a 1198-line local `CommandBase` and hand-rolled formatting, error handling and outcome beside it; the three commands here total under 200 lines because none of that is repeated.

## Mutation table

Every fence this thread adds, broken on purpose and seen red, then restored. A fence that cannot fail is not a fence.

| #   | Mutation                                                | Fence                   | Result    |
| --- | ------------------------------------------------------- | ----------------------- | --------- |
| M1  | summary sliced to the first three stages                | stage_agnostic_fence    | red (0/3) |
| M2  | summary hardcoded to the shipped three loop names       | stage_agnostic_fence    | red (0/3) |
| M3  | the CSV rescue stops naming its exception type          | service/no_rescue_fence | red       |
| M4  | an `after` block added to the service layer             | service/no_rescue_fence | red       |
| M5  | the service names the CLI framework                     | boundary_fence          | red       |
| M6  | the pattern layer names the service                     | boundary_fence          | red       |
| M7  | a command reaches past the service to the pattern layer | thin_coordinator_fence  | red       |
| M8  | the mix task reaches into the service                   | mix_task_test           | red       |
| M9  | the stage table sliced to the shipped three rows        | sia_run_command_test    | red       |
| M10 | `:url` removed from `config/config.exs`                 | cli/config_test         | red       |

**M2 is the one worth reading.** With the summary hardcoded to `[signal_loop: 9, inference_loop: 6, action_loop: 6]`, the shipped-pipeline test still passed -- it asserts exactly those three values. What caught it was the four-loop fence, and, separately, the one service test that runs a _different_ pipeline (`sense_pipeline`). A project that only ever tested its own shipped definitions would have shipped this defect, which is precisely how the archived layer shipped it.

## Critic rounds

One round, clean. `intent critic elixir --severity-min style` over the 24 files this thread touched: no findings at any severity. Whole-tree sweep over all 105 files in `lib/` + `test/`: no findings at any severity.

## Gate

`mix gate` green at close: **443 passed** (69 doctests, 374 tests), 756 mods/funs, zero credo findings at `--strict`. Up from 363/642 at ST0003's close.

## Two things found the hard way

**The bare invocation was broken while every subcommand worked.** `sia.run`, `sia.pipelines`, the escript and `bin/riffle cli sia.*` were all verified green, and on that basis the binding was reported as working. hv then ran `bin/riffle cli` with no arguments and got a stack trace: the framework reads `:url` with `fetch_env!` to print its intro banner, and `config/config.exs` did not set it. `:prompt_symbol` was missing the same way and would have taken the REPL down next.

The fix for the two keys is trivial. The fix for the _class_ is `test/riffle/cli/config_test.exs`, which reads the framework's own source, collects every `Application.fetch_env!(:arca_cli, key)` call, and requires each key to be configured. A new required key in a future arca_cli now arrives as a red test rather than as a stack trace in front of a user. The lesson is narrower than "test more": verifying the paths a _builder_ exercises says nothing about the paths a _new user_ reaches first, and those are different paths.

**`app: nil` in the escript config produced a binary that built and then died.** Copied from the archive without thinking about what it means: no OTP application starts, so the framework's configuration server is not running, and the first command exits on a GenServer no-process. `app: :riffle` starts the app and its dependencies with it.

## Departures from the plan

- **`sia.pipelines` was going to be scoped to file sources.** `Riffle.Predicate.PipelineConfig` turned out to already declare `list_pipelines/0`, so module sources list too, and the command works uniformly across the source vocabulary.
- **CSV was going to be hand-rolled.** The plan argued for that to hold the dependency count at zero. Taking `arca_cli` (which brings optimus, arca_config, jason, owl and ex_prompt) killed the argument, so `nimble_csv` does it instead.
- **The dependency is pinned to `tag: "v0.5.0"`, not `branch: "main"`.** A dependency that can change underneath a green gate defeats the gate. hv has hex publication of `arca_config` and `arca_cli` on the plan; this becomes an ordinary version requirement then, and Riffle's own publication unblocks with it.
