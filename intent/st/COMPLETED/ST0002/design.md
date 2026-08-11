# Design - ST0002: ctx-next: the Bowtie waist

## Approach

Riffle needs a run context. Multiplyer had one -- an 18-field struct with 76 public functions across 5,964 lines -- and it is not being ported. This thread builds its replacement to the shape of The Bowtie Pattern: typed perturbations in, a pure knot against immutable state, typed emissions out.

The work order is spec-first, per WP: write the contract in this document, write the acceptance test against the contract, then write the code that satisfies it. Tests assert what the contract promises, never how the current code happens to produce it.

The acceptance tests are conformance fences wherever the property is a whole-class invariant. A fence answers a completeness question by enumerating the source of truth exhaustively rather than spot-checking examples, which is why it catches the drift class a hand-written test misses. Riffle already had one before this thread (`extrication_gate_test.exs`); this thread adds four more.

## Design Decisions

### DD-1 -- Riffle is an example of the pattern, not its reference implementation

hv ruling, 2026-08-10. The Bowtie is a conceptual idea; Riffle follows it because the discipline earns its keep here, not to demonstrate the pattern's generality to anyone.

The consequence is subtractive. Nothing is built to showcase extensibility: no generic contract kit for third-party types, no subscriber routing table, no consumer fan-out registry, no `z_order` (a rendering concern Riffle does not have), no fidelity ladder (Riffle has no inference provider to swap). What remains is the machinery Riffle actually consumes.

The inherited framing -- "Riffle is intended as the open-source reference implementation of the published Bowtie pattern" -- came from the Multiplyer triage session and appeared in both this thread's info.md and the extrication handoff. It was read as a requirement and it steered this thread's first design toward a framework. Both occurrences are struck, with the correction recorded in the handoff rather than silently deleted.

### DD-2 -- The composite root is typed; there is exactly one declared overlay

The context is a typed composite root with named slots, each carrying a declared type, accessed by dot so a field typo fails at the call site. Exactly one slot is a free-form overlay (`metadata`), and it is declared as such.

This is the single most directly applicable lesson available to this thread. A god-object context is the largest source of cross-cutting drift in a state-bearing system, and Multiplyer's `Ctx` was precisely that: inputs, outputs, cargo, metadata and options all free-form maps on one struct, mutated through 76 accessors. The typed-composite shape is the durable answer, and it holds only if it is architecture rather than a code-review preference -- hence AC-01.1 is a fence, not a guideline.

### DD-3 -- Both catalogs are closed registries; an unknown tag loud-fails

Every perturbation and emission is a typed struct declaring a tag and a typespec. Each catalog's parent module enumerates its implementations in a closed list and builds the tag-to-module map at compile time. Lookup of an unknown tag returns a tagged error rather than falling through.

Adding a type is therefore a deliberate ritual -- author the struct, add the registry entry -- and the catalog never grows silently. AC-01.3 fences the bijection in both directions, so a struct authored without a registry entry fails the build rather than becoming an invisible type.

### DD-4 -- Multi-clause dispatch, not a subscriber routing table (named trade-off)

The knot dispatches on the perturbation struct with multi-clause heads. It has no subscription registry, because Riffle has no independent subscribers competing for tags -- SIA is a small number of staged steps, not twenty independently-authored mechanics. A routing table for that population would be a dispatch table impersonating architecture.

The cost is real and is named here rather than discovered later: adding a perturbation touches three places (the struct, the registry entry, a knot clause) where a subscription model would touch two, because the third place is a central dispatch point. The delivery-floor fence (AC-02.3) is what makes that safe -- a perturbation with no clause produces no emission and fails the fence immediately, so the missing clause cannot pass silently.

If a later thread turns up genuinely independent handlers, moving to subscriptions is a change to this document, argued, not a local refactor smuggled into a WP.

### DD-5 -- The Predicate engine is an inferential edge, never inside the knot

This falls out of DD-2 and the purity commitment, and it shapes ST0003 more than anything else here.

Inference is broader than LLMs: rules engines, classical models and human-in-the-loop interpretation are all inference modes, and the discipline is that inference lives at an edge. The Predicate engine is a rules engine. It is also, concretely, impure -- evaluation runs through an ETS-backed cache owned by a GenServer -- so predicate evaluation inside the knot would break purity outright rather than approximately.

So the two halves compose only at an edge: an edge component evaluates predicates and feeds the typed result in as a perturbation; the knot threads run state and produces emissions. Both directions are fenced -- the waist names no engine module (AC-01.4) and the engine names no waist module (AC-01.5) -- which makes them independent by construction. ST0003 owns the edge that joins them.

A corollary: emission payloads are opaque to the waist. Results travel as payloads the waist does not inspect, and encoding goes through a protocol rather than a pattern-match on engine types. This is also what keeps handoff stitch 2 (`ctx/formatter/json.ex` pattern-matching `%Predicate.Item{}`) from re-forming.

### DD-6 -- Perturbations and emissions are not persisted in the context

They are transient runtime primitives: perturbations enter, emissions leave, neither is stored. No slot on the context accumulates them.

This corrects the shape Multiplyer had, where `record_event` and the `event_*` family wrote events into the context struct. In the bowtie an event is an emission and leaves; a consumer that wants a log keeps one. Replay reconstructs a run from the perturbation stream, which is the reason the replay property (AC-02.5) is cheap to assert.

### DD-7 -- The knot emits the full stream unconditionally

The knot takes no consumer, mask, or verbosity argument and never branches its generation on who is listening. Filtering is a consumer's business, applied after the fact.

This is why `verbose?` does not survive the translation, and it is what keeps the knot's output a function of its inputs alone -- which is the precondition for both determinism (AC-02.2) and replay (AC-02.5).

## Capability map

The minimum surface is measured, not guessed: the Ctx functions the extricated code actually consumed, by call-site count, from `intent/docs/extrication-handoff.md`. Twenty are expressed through the typed model; four are dropped with reasons. AC-03.1 fences this map against the live catalogs so a mapping cannot rot into a claim.

| Measured call (sites)                                            | ctx-next expression                                                                       |
| ---------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `Ctx.t` (34)                                                     | the composite root type                                                                   |
| `with_status` (17), `complete` (2)                               | status slot + `StatusChanged` emission; a transition is never a setter                    |
| `set_metadata_value` (14)                                        | the declared `metadata` overlay + `MetadataSet` emission                                  |
| `new` (12), `set_opt` (1)                                        | construction with typed options, immutable thereafter                                     |
| `debug` (11), `log` (4)                                          | `Diagnostic` emission carrying its level; realised by a consumer                          |
| `event_started` (5), `event_completed` (8), `event_progress` (1) | the three event emissions                                                                 |
| `add_error` (8)                                                  | errors slot + `ErrorRaised` emission                                                      |
| `set_input` (6), `with_inputs` (5)                               | input slot, written by applying a perturbation                                            |
| `set_output` (4)                                                 | output slot + `OutputProduced` emission                                                   |
| `get_input` (4), `get_output` (2)                                | typed slots, read by dot -- a pass-through accessor is where a 76-function surface starts |
| `has_errors?` (3)                                                | a derived predicate on the composite root                                                 |
| `get_metadata` (1)                                               | `fetch_metadata/2`, tagged -- a recorded value may itself be nil                          |

Dropped, each with its reason:

| Dropped (sites)                            | Why                                                                                                                                                                                                     |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `set_cargo_item` (5), `get_cargo_item` (1) | Cargo was an untyped scratch bag for inter-stage carry -- exactly what the composite root exists to refuse. A stage's product leaves as an emission; ST0003 owns the concrete carry between its stages. |
| `record_event` (3)                         | Events are emissions and they leave (DD-6). Recording them into the context is the shape being replaced.                                                                                                |
| `verbose?` (1)                             | The core never branches on who is listening (DD-7). Verbosity is a consumer's concern.                                                                                                                  |
| `Stats.get_all_stats` (1)                  | Derivable from the emission stream by a consumer. Counters in the waist would make the knot a bookkeeper and invite mutation.                                                                           |

## Architecture

```
Riffle.Ctx                 -- THE state: typed composite root, one declared overlay
Riffle.Ctx.Knot            -- apply/2: pure, total, multi-clause; the single state-transition point
Riffle.Ctx.Perturbation    -- closed registry + the typed input structs beneath it
Riffle.Ctx.Emission        -- closed registry + the typed output structs beneath it
```

Four concerns, four modules, each registered in `intent/llm/MODULES.md` before it is written.

## Alternatives Considered

**Port the surface, modernise later.** Rejected before the thread opened: the handoff dispositions `ctx/` as not ported. Serving 76 accessors through a nicer facade preserves the bag-of-maps API shape, which is the defect.

**A generic Bowtie framework with pluggable contracts.** This thread's first design, rejected under DD-1. It existed to make a reference-implementation claim true, and that claim is not a requirement.

**A subscriber routing table mirroring Lamplight's engine.** Rejected under DD-4 on population grounds, with the trade-off named and the fence that covers it.

**Predicate evaluation inside the knot.** Rejected under DD-5 -- it would make the knot impure through the evaluation cache, and inference belongs at an edge regardless.
