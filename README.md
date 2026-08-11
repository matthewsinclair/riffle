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

- Architectural commitments and their fences: `intent/docs/bedrock.md`
- Extrication charter and bill of materials: `intent/docs/extrication-handoff.md`
- Work tracking: `intent/st/` (steel threads)
- Design marks: `design/`

## Licence

[MIT](LICENSE).
