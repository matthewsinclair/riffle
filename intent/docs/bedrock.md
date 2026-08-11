# Architectural Bedrock -- Riffle

> The commitments Riffle is built on. A contradiction with this document is a bug in the contradicting document, not a choice. Established by ST0002 (2026-08-10) and extended by ST0003, ST0004 and ST0005 (2026-08-11); a change to any commitment here is a change to the shape of the system, argued at this level, never taken locally inside a work package.

## Preamble

Riffle is a predicate engine and a sense-infer-act pattern layer sitting on a context waist, with a service module as the way in and a CLI over that. The waist follows The Bowtie Pattern (Sinclair, Feb 2026).

Five layers, and the shape of the whole is which of them may name which. Each names the one below it and is named by none of them.

The engine names nothing. The waist names nothing. The pattern layer names both, and is named by neither -- it is the edge where they compose, and it is the only place they do. The service names the pattern layer and no delivery mechanism. The CLI names the service and nothing beneath it.

Riffle is **an example** of that pattern, not its reference implementation. The pattern is a conceptual idea; nothing here exists to demonstrate its generality. Each commitment below is kept because it earns its keep in this codebase, and every one of them is enforced by a fence rather than by memory or review taste. The distinction matters: Riffle borrows the discipline, not the obligation to showcase it.

## The commitments

### 1. The waist is a bowtie

`f(perturbation, state) -> (state', emissions)`. Typed perturbations converge on a pure knot; the knot produces typed emissions that fan out to whatever consumes them. As built: `Riffle.Ctx.Knot.tick/2`.

### 2. The knot is unconditionally pure

Not approximately pure. Nothing reachable from the knot reads a clock, generates a random value, touches a process or an ETS table, opens a file, or logs. Non-determinism enters as data or not at all -- which is why the context is constructed with a run id supplied by the caller rather than one minted inside.

Purity is what buys determinism and exact replay. "Pure except for this one call" forfeits both, so there is no approximate-pure.

### 3. The context is a typed composite root

Every slot carries a declared type and is reached by dot access. Exactly one slot is a free-form overlay, and it is declared as such. A god-object context is the largest source of cross-cutting drift in a state-bearing system; the typed-composite shape is the durable answer, and it holds only because it is checked, not because it is preferred.

The context exposes reads and construction. The one way to change it is to apply a perturbation, so the transition is a single auditable point.

### 4. Perturbations and emissions are typed, and their catalogs are closed

Every type is a struct with a tag and a typespec, enumerated in a closed registry with the tag map built at compile time. An unknown tag loud-fails. Adding a type is a deliberate two-step ritual; the catalog never grows silently.

### 5. Perturbations and emissions are transient

They enter and they leave. Neither is persisted in the context, and no slot accumulates them. A consumer that wants a log keeps one; replay reconstructs a run from the perturbation stream.

### 6. Inference lives at an edge

Inference is broader than LLMs: rules engines, classical models, and human-in-the-loop interpretation are all inference. Riffle's Predicate engine is a rules engine, and it is also impure -- evaluation runs through a cache owned by a process. So it lives at an edge: an edge component evaluates and feeds the typed result in as a perturbation.

The waist names no engine module and the engine names no waist module. They compose only where an edge joins them, and the edge is named by neither -- the core does not know who is listening, and the engine does not know what it is being used for. As built: `Riffle.Sia`, which stages a predicate pipeline through the knot, evaluating at the edge and feeding each typed result in as a perturbation.

### 7. Every failure surfaces as a typed signal

No silent no-op, no rescue-and-swallow. An unrecognised tag returns an error; a struct outside the catalog raises; a perturbation that no clause claims surfaces as a typed default pass rather than vanishing.

There are two kinds of failure and they are treated differently on purpose. A failure a correct program can meet at runtime -- a missing file, a name nothing defines, an unset configuration -- is a **tagged error**, and where it happens inside a run it fails that run as a typed signal a caller can read. A failure that means the program is wrong -- a value outside a declared vocabulary, an argument that contradicts another -- **raises**, naming what arrived. Neither is ever a quiet empty result.

### 8. No derived claim outlives its evidence

Established by ST0003, from the defect that thread was built to eliminate: a run computed correct results, derived statistics from them, discarded the results, and recorded a flag saying the results were available. The flag was not stale -- it was false the moment it was written.

So: a count, a statistic or a status is recorded only alongside the collection it describes, and it is computed as a projection of facts already emitted rather than tallied in parallel. Where results are reported in more than one place, the places must agree exactly. A statistic that needs a fence to stay honest is a statistic that should have been a projection.

### 9. The way in is the service, and it names no delivery mechanism

`Riffle.Service.run/1` holds the business logic of a run -- read the rows, resolve the pipeline, stage it, report what happened -- and every caller enters there: the CLI command, the mix task, an Elixir caller with rows of its own. The service names no CLI framework, so the library is usable by someone who wants none of one.

The direction is the commitment, and it runs both ways. The engine, the waist and the pattern layer name no service module either. The service is above them, and they do not know it exists.

### 10. A coordinator is thin, and thin is a fence

A CLI command parses, makes one call, and renders. It may name the service and nothing beneath it: no engine module, no waist module, no pattern-layer module. Put that way, "thin coordinator" stops being a style assertion and becomes a mechanical property -- a command that starts doing the work has to name something it is not allowed to name.

One doorway, one parser. `mix riffle.cli` and the escript both hand argv to the framework rather than reading it themselves, so exactly one place decides what a flag means. A second doorway that grew its own parser would be a second answer to that question.

### 11. A documentation claim is checked, not reviewed

Wherever a machine can check what a document says, it does. Every `fun/arity` reference in every doc resolves. Every documented example is a doctest that runs. Every `.pred` snippet in the language reference loads through the loader a reader's own file goes through, and every documented expression is evaluated rather than parsed -- because parsing succeeds for text that the evaluator will refuse. The standard library's documented surface is derived from the modules, so a new builder makes the reference red until it is written up. Every route in the README resolves to something that exists.

The reason is the same as for every other fence here. A document reviewed once is correct once. The moduledoc of the module named after the project taught a model the architecture had already refuted, and forty-four lines of examples had never run -- in a tree where every other claim was already fenced.

## The NOT-list

Stated negatively, because the failure modes a state-bearing system is prone to are violations of the negative form.

- **The knot is not approximate-pure.** One logger call is a violation, not a pragmatic exception.
- **The context is not a god-object.** No untyped slot, no free-form map beyond the one declared overlay, no "we will type it later".
- **Perturbations and emissions are never untyped.** No maps, no stringly-typed atoms, no type outside its registry.
- **The waist is not a framework.** No extensibility surface exists for its own sake. If a mechanism has no consumer in Riffle, it is not built.
- **The engine and the waist do not name each other.** Neither direction, at any depth of the call closure.
- **Nothing but the knot changes a context.** No reaching in, in either spelling of update syntax, anywhere outside the waist.
- **No availability flag.** The presence of the thing is the fact. A boolean asserting that a payload exists, next to the payload, is redundant; without the payload it is a lie waiting to happen.
- **The library does not name a delivery mechanism.** No CLI-framework module anywhere outside the CLI layer, and no service module anywhere below the service.
- **A coordinator does not do the work.** No CLI module reaches past the service into the engine, the waist or the pattern layer, at any depth.
- **There is not a second argv parser.** A doorway hands argv to the one parser; it does not grow its own.
- **A documented claim is not taken on trust.** If a machine can check it, the unchecked version does not ship.

## How the commitments are held

Each is enforced mechanically, by a fence that enumerates the source of truth exhaustively rather than sampling examples. A fence catches the drift class a hand-written test misses.

| Commitment                    | Fence                                                                                                                       |
| ----------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| Purity (2)                    | `purity_fence_test` -- walks the compiled call closure from the knot                                                        |
| Typed composite root (3)      | `ctx_test` -- reads the declared typespec, not the runtime values                                                           |
| Closed catalogs (4)           | `catalog_fence_test` -- modules on disk against registry, and union type against membership                                 |
| Transience (5)                | `ctx_test` -- no slot's type references a catalog namespace                                                                 |
| Edge separation (6)           | `boundary_fence_test` (parsed AST, four directions), `purity_fence_test` (call closure)                                     |
| No silent failure (7)         | `delivery_floor_fence_test` -- every perturbation yields a real emission, no default                                        |
| No silent failure (7)         | `sia/no_rescue_fence_test` -- no rescue, catch or after in the pattern layer                                                |
| No derived claim alone (8)    | `sia/evidence_fence_test` -- results agree in three places; every count carries its collection                              |
| Single transition point (3)   | `single_transition_fence_test` -- no context update outside the knot, either spelling                                       |
| Measured surface              | `measured_surface_fence_test` -- both directions, capability to type and back                                               |
| Service is the way in (9)     | `boundary_fence_test` -- the engine, the waist and the pattern layer name no service module                                 |
| No delivery below the CLI (9) | `boundary_fence_test` -- nothing outside the CLI layer names a CLI-framework module                                         |
| Thin coordinator (10)         | `cli/thin_coordinator_fence_test` -- no CLI module names an engine, waist or pattern-layer module                           |
| One argv parser (10)          | `cli/mix_task_test` -- the mix task names the framework and no Riffle module at all                                         |
| No silent failure (7)         | `service/no_rescue_fence_test` -- every rescue in the service names its type; no catch, no after                            |
| A stage is a loop             | `service/stage_agnostic_fence_test` -- a four-loop pipeline summarises as four stages, under their own names                |
| Configuration completeness    | `cli/config_test` -- every app-env key the framework fetches with `fetch_env!` is set                                       |
| Documentation is checked (11) | `docs/doc_conformance_test` -- references resolve, examples run, catalog members describe their fields, README routes exist |
| Documentation is checked (11) | `docs/pred_reference_test` -- snippets load and materialise, expressions evaluate, the standard-library surface is derived  |

Every fence is mutation-checked when written: break the thing it guards, and it goes red. A fence that cannot fail is not a fence -- and one of these was exactly that for a while, matching the Erlang remote-type form with the wrong arity so that it silently recognised nothing. Two fences now carry positive controls for that reason.

## Realisation today

These sit outside bedrock and evolve freely.

- **Elixir**, with the compiler's type checker doing real work -- it proved the delivery floor's empty-result clause unreachable and the closed registry non-empty.
- **Multi-clause dispatch** in the knot rather than a subscriber routing table, because Riffle has no independent subscribers competing for tags. The trade-off and the fence that covers it are in ST0002 design.md, DD-4.
- **No fan-out registry.** The knot returns emissions; the caller decides. One consumer does not justify a registry.
- **No z-order on emissions.** That is a rendering concern, and Riffle does not render.
- **A stage is a loop.** The pattern layer takes a pipeline's loop sequence as its staging and names each stage for its loop, so sense-infer-act is what a definition file says rather than a shape the runner imposes. No stage registry, no behaviour, no tag-prefix convention.
- **No datasource layer.** The engine, the waist and the pattern layer take an enumerable of field maps or items and nothing else; reading a file is the service's job, one layer up, and CSV is the only format it reads. A fan-in source is a natural later addition that would then genuinely prove source independence; adding one now would prove nothing.
