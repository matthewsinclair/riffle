# Riffle

<p align="center"><img src="design/riffle-mark.svg" width="160" alt="Riffle: a stream runs over riffle bars; the gold stays caught"></p>

> Sense → infer → act over data streams. The stream flows through; the signal stays.

Riffle runs data streams over composable predicate pipelines in three tag-driven stages: **sense** (`signal_*` predicates detect patterns in each item and tag it), **infer** (`inference_*` predicates match combinations of signal tags and add insight tags), **act** (`action_*` predicates fire on inference tags). The predicates are the riffles: the stream passes through unimpeded, and what matters gets caught.

## Status

Pre-alpha; extraction in progress. The engine (Predicate) and pattern layer (SIA) are being extricated from [Multiplyer] (2025), the pattern's first incarnation, and the context waist (`ctx-next`) is being rebuilt to the spec of **The Bowtie Pattern** (Sinclair, 2026). Riffle is intended as the pattern's open-source reference implementation: sources fan in as typed perturbations, a pure knot processes them against immutable state, consumers fan out on typed emissions.

- Extrication charter and bill of materials: `intent/docs/extrication-handoff.md`
- Work tracking: `intent/st/` (steel threads)
- Design marks: `design/`

## Licence

TBD (decided before first release).
