# Riffle

<p align="center"><img src="design/riffle-mark.svg" width="160" alt="Riffle: a stream runs over riffle bars; the gold stays caught"></p>

> Sense → infer → act over data streams. The stream flows through; the signal stays.

Riffle runs data streams over composable predicate pipelines. Each item flows through a sequence of stages; a stage keeps the items at least one of its predicates matches, and tags them as it goes. The predicates are the riffles: the stream passes through unimpeded, and what matters gets caught.

The shipped definitions are three stages -- **sense** (predicates reading the raw fields), **infer** (predicates matching combinations of sense tags), **act** (predicates firing on inference tags) -- but that is what those definitions say, not a shape the runner imposes. A stage is just a loop, and a pipeline with four of them runs as four stages with no code change.

## Shape

Five layers, and the architecture is which of them may name which. Each names the one below it and is named by none of them.

- **The engine** (`Riffle.Predicate`) evaluates predicates, loops and pipelines, from Elixir or from `.pred` files. It names nothing else.
- **The waist** (`Riffle.Ctx`) is a bowtie: typed perturbations fan in, a pure total knot turns each into new state plus typed emissions, and those fan out. It names nothing else.
- **The pattern layer** (`Riffle.Sia`) is the edge where the two compose. It stages a pipeline loop by loop, evaluating at the edge and applying each result to the knot. It names both, and neither names it.
- **The service** (`Riffle.Service`) is the way in: read rows, run a pipeline, report what happened. It holds the business logic and names no CLI framework, so the library stays usable without one.
- **The CLI** (`Riffle.Cli`) is a thin coordinator over the service: parse, one call, render. It may name no engine, waist or pattern-layer module at all.

Every one of those claims is held by a conformance fence in the test suite rather than by convention -- including the last, so "thin coordinator" is a mechanical property rather than a style assertion. The commitments and the fence that enforces each are in `intent/docs/bedrock.md`.

## Status

Pre-alpha, and the extraction is complete. The engine and the pattern layer were extricated from Multiplyer (2025), the pattern's first incarnation, and the context waist was rebuilt to the spec of **The Bowtie Pattern** (Sinclair, 2026). Riffle is *an example* of that pattern rather than its reference implementation: nothing here exists to demonstrate the pattern's generality, and every mechanism has a consumer in Riffle or is not built.

What is not here yet: no streaming, no datasource layer beyond reading a CSV, no persistence.

## Using it

Not on hex yet -- neither is `arca_cli`, which the CLI is built on -- so as a dependency it is:

```elixir
{:riffle, github: "matthewsinclair/riffle"}
```

From the command line:

```
$ riffle sia.pipelines --from priv/sia/sia.pred
* infer_pipeline
* main
* sense_pipeline

$ riffle sia.run --input priv/sia/sample.csv --from priv/sia/sia.pred
✓ main: 6 of 10 rows kept
┌────────────────┬──────┐
│ stage          │ kept │
├────────────────┼──────┤
│ signal_loop    │ 9    │
│ inference_loop │ 6    │
│ action_loop    │ 6    │
└────────────────┴──────┘
```

One row per loop the pipeline declares, under that loop's own name. A pipeline with four loops prints four rows, with no code change -- which is the same claim the second paragraph of this README makes, held by a fence rather than by intent.

`--format json` gives the same run as structured output. `mix riffle.cli` runs the CLI in a checkout, `mix escript.build` produces the standalone `riffle` binary, and `riffle repl` is an interactive shell over the same commands.

From Elixir, the service is the way in:

```elixir
{:ok, result} =
  Riffle.Service.run(
    input: "data.csv",
    source: {:file, "definitions.pred"},
    pipeline: :main
  )

result.stages       #=> [signal_loop: 9, inference_loop: 6, action_loop: 6]
result.ctx.output   #=> the surviving items, tagged
result.emissions    #=> the full evidence of the run
```

`Riffle.Sia.run/4` is one level below that, for a caller who already has rows and wants the pattern layer directly.

## Defining the predicates

Definitions live either in a `.pred` file or in an Elixir module, and the two forms say the same things in the same words. A predicate is a name, a description and an expression. A loop is a group of predicates, ORed, and one loop is one stage of a run. A pipeline is a sequence of loops, ANDed, so each stage is a strictly narrower cut than the one before it.

```elixir
predicate(:signal_high_activity, "Users with high login activity") do
  expr(@login_count > 50)
end

predicate(:inference_upsell_opportunity, "Identifies upsell opportunities") do
  expr(has_tag(:signal_high_activity) && !has_tag(:signal_premium_account))
end

loop(:signal_loop, "Signal detection") do
  predicate(:signal_high_activity)
end

pipeline(:main, "The complete sense-infer-act pipeline") do
  loop(:signal_loop)
  loop(:inference_loop)
  loop(:action_loop)
end
```

`@login_count` reads that field off the item; `has_tag/1` asks what earlier stages concluded about it. An item carries the name of every predicate that matched it, which is what lets a later stage match on an earlier stage's finding -- and that, rather than anything in the runner, is the whole of sense to infer to act.

`priv/sia/sia.pred` is the full shipped set. `Riffle.Sia.DefaultPipeline` is the same definitions as compiled Elixir, and a test holds the two to producing identical items with identical tags.

## Where to go next

| For                                  | Read                                                                      |
| ------------------------------------ | ------------------------------------------------------------------------- |
| The `.pred` language, in full        | [docs/pred-language.md](docs/pred-language.md)                            |
| The API, module by module            | `mix docs`, then `doc/index.html` -- grouped by the five layers above     |
| The architecture and what holds it   | `intent/docs/bedrock.md` -- the commitments, each bound to its fence      |
| What came from where, and why        | `intent/docs/extrication-handoff.md`                                      |
| The work, thread by thread           | `intent/st/`                                                              |
| The marks                            | `design/`                                                                 |

## Licence

[MIT](LICENSE).
