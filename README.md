# Riffle

<p align="center"><img src="design/riffle-mark.svg" width="160" alt="Riffle: a stream runs over riffle bars; the gold stays caught"></p>

> Sense → infer → act over data streams. The stream flows through; the signal stays.

Riffle runs data streams over composable predicate pipelines. Each item flows through a sequence of stages; a stage keeps the items at least one of its predicates matches, and tags them as it goes. The predicates are the riffles: the stream passes through unimpeded, and what matters gets caught.

The shipped definitions are three stages -- **sense** (predicates reading the raw fields), **infer** (predicates matching combinations of sense tags), **act** (predicates firing on inference tags) -- but that is what those definitions say, not a shape the runner imposes. A stage is just a loop, and a pipeline with four of them runs as four stages with no code change.

## Shape

Three parts, and the architecture is which of them may name which.

- **The engine** (`Riffle.Predicate`) evaluates predicates, loops and pipelines, from Elixir or from `.pred` files. It names nothing else.
- **The waist** (`Riffle.Ctx`) is a bowtie: typed perturbations fan in, a pure total knot turns each into new state plus typed emissions, and those fan out. It names nothing else.
- **The pattern layer** (`Riffle.Sia`) is the edge where the two compose. It stages a pipeline loop by loop, evaluating at the edge and applying each result to the knot. It names both, and neither names it.

Every one of those claims is held by a conformance fence in the test suite rather than by convention. The commitments and the fence that enforces each are in `intent/docs/bedrock.md`.

## Status

Pre-alpha, and the extraction is complete. The engine and the pattern layer were extricated from Multiplyer (2025), the pattern's first incarnation, and the context waist was rebuilt to the spec of **The Bowtie Pattern** (Sinclair, 2026). Riffle is *an example* of that pattern rather than its reference implementation: nothing here exists to demonstrate the pattern's generality, and every mechanism has a consumer in Riffle or is not built.

What is not here yet: no CLI, no datasource layer, no persistence. A caller builds a context, hands `Riffle.Sia.run/4` some rows and a pipeline source, and reads the results off the returned context and emission stream.

- Architectural commitments and their fences: `intent/docs/bedrock.md`
- Extrication charter and bill of materials: `intent/docs/extrication-handoff.md`
- Work tracking: `intent/st/` (steel threads)
- Design marks: `design/`

## Licence

[MIT](LICENSE).
