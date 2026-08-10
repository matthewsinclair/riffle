# Architectural Bedrock -- Riffle

> The commitments Riffle's waist is built on. A contradiction with this document is a bug in the contradicting document, not a choice. Established by ST0002 (2026-08-10); a change to any commitment here is a change to the shape of the system, argued at this level, never taken locally inside a work package.

## Preamble

Riffle is a predicate engine and a sense-infer-act pattern layer sitting on a context waist. The waist follows The Bowtie Pattern (Sinclair, Feb 2026).

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

The waist names no engine module and the engine names no waist module. They compose only where an edge joins them.

### 7. Every failure surfaces as a typed signal

No silent no-op, no rescue-and-swallow. An unrecognised tag returns an error; a struct outside the catalog raises; a perturbation that no clause claims surfaces as a typed default pass rather than vanishing.

## The NOT-list

Stated negatively, because the failure modes a state-bearing system is prone to are violations of the negative form.

- **The knot is not approximate-pure.** One logger call is a violation, not a pragmatic exception.
- **The context is not a god-object.** No untyped slot, no free-form map beyond the one declared overlay, no "we will type it later".
- **Perturbations and emissions are never untyped.** No maps, no stringly-typed atoms, no type outside its registry.
- **The waist is not a framework.** No extensibility surface exists for its own sake. If a mechanism has no consumer in Riffle, it is not built.
- **The engine and the waist do not name each other.** Neither direction, at any depth of the call closure.

## How the commitments are held

Each is enforced mechanically, by a fence that enumerates the source of truth exhaustively rather than sampling examples. A fence catches the drift class a hand-written test misses.

| Commitment                    | Fence                                                                              |
| ----------------------------- | ------------------------------------------------------------------------------------ |
| Purity (2)                    | `purity_fence_test` -- walks the compiled call closure from the knot                 |
| Typed composite root (3)      | `ctx_test` -- reads the declared typespec, not the runtime values                    |
| Closed catalogs (4)           | `catalog_fence_test` -- modules on disk against registry, and union type against membership |
| Transience (5)                | `ctx_test` -- no slot's type references a catalog namespace                          |
| Edge separation (6)           | `boundary_fence_test` (parsed AST, both directions), `purity_fence_test` (call closure) |
| No silent failure (7)         | `delivery_floor_fence_test` -- every perturbation yields a real emission, no default |
| Measured surface              | `measured_surface_fence_test` -- both directions, capability to type and back        |

Every fence is mutation-checked when written: break the thing it guards, and it goes red. A fence that cannot fail is not a fence -- and one of these was exactly that for a while, matching the Erlang remote-type form with the wrong arity so that it silently recognised nothing. Two fences now carry positive controls for that reason.

## Realisation today

These sit outside bedrock and evolve freely.

- **Elixir**, with the compiler's type checker doing real work -- it proved the delivery floor's empty-result clause unreachable and the closed registry non-empty.
- **Multi-clause dispatch** in the knot rather than a subscriber routing table, because Riffle has no independent subscribers competing for tags. The trade-off and the fence that covers it are in ST0002 design.md, DD-4.
- **No fan-out registry.** The knot returns emissions; the caller decides. One consumer does not justify a registry.
- **No z-order on emissions.** That is a rendering concern, and Riffle does not render.
