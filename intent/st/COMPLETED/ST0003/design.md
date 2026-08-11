# Design - ST0003: SIA pattern layer rewrite

## Approach

The pattern layer is built as the **edge** that joins the two halves ST0002 deliberately kept apart. The engine evaluates predicates; the waist holds run state; neither names the other, and neither names this layer. `Riffle.Sia` runs a predicate pipeline stage by stage, applying a typed perturbation to the knot at every step and collecting the emissions the knot returns.

Work order per WP is spec then test then code, and the tests are conformance fences wherever the property is a whole-class invariant. Three of them exist specifically because the source layer's central defect (D2) was not a bug in a branch -- it was a shape that allowed a run to report success while its results had been thrown away.

## Design Decisions

### DD-1 -- The pattern layer is the edge, and it is the only thing that knows both halves

Bedrock commitment 6: inference lives at an edge. The Predicate engine is a rules engine, which is inference, and it is impure -- evaluation runs through an ETS cache owned by a process. So it cannot be inside the knot. The waist is pure and knows nothing of who consumes it.

`Riffle.Sia` names both. Neither names it, in either direction, and both directions are fenced (AC-01.6, AC-01.7). The engine direction matters most: the source layer hardcoded a fallback to its own default-pipeline module _inside the engine_, and that was the one stitch that lived in ported code. Severing it was ST0001's job; keeping it severed is this thread's, and it only becomes checkable now that a pattern layer exists to be named.

### DD-2 -- A stage is a loop

The pipeline's loop sequence **is** the staging. Stage identity is the loop's own name, read off the struct. There is no stage registry, no mapping table, and no convention parsed out of tag prefixes.

This falls out of what the engine already does: a loop ORs its predicates, a pipeline ANDs its loops, and items accumulate tags as they survive each one. Sense/infer/act is then a three-loop pipeline whose loops happen to be named for the three stages -- the shipped `sia.pred` is an _instance_ of the pattern, not a structure the layer imposes. A four-stage pipeline works without a line changing.

The cost is that the layer cannot check "is this really sense-infer-act", and it should not: that is a property of a definition file, not of the runner.

### DD-3 -- Results travel three ways, and the three must agree

The root cause of D2, recorded in ST0001: `update_statistics/3` materialised the results stream, derived tag counts from it, and discarded the results. The success path then set `results_available: true`. The flag was not stale or racy -- it was false at the moment it was written, and the characterisation tests read the default `[]` structurally, so no assertion could see it.

A completed run puts its results in three places: the final stage's `StageCompleted` output, the `OutputProduced` emission payload, and `ctx.output`. AC-01.2 fences all three to the same value. The defect that started this thread is now a compile-and-test-time failure rather than a silent lie, because there is no longer any single place a result can be dropped without the other two disagreeing.

### DD-4 -- One derived fact, and it recomputes

The negative half of DD-3. The layer records exactly one thing in metadata -- `:stage_counts`, a keyword list of loop name to retained count -- and the fence recomputes it from the stage emissions in the same stream. `Riffle.Sia.metadata_keys/0` is the declared closed set; a `MetadataSet` emission naming anything else fails the fence.

So a statistic cannot be recorded without the collection it counts, and a new statistic cannot be added without also making it recomputable. `results_available` has no way back in: it is not a declared key, and there is nothing to recompute it from.

A keyword list rather than a map because two loops may legitimately share a name, and a map would silently merge them -- which is the same class of error the whole thread is about.

### DD-5 -- The knot is the only transition, and that is now fenced

Bedrock commitment 3 says the one way to change a context is to apply a perturbation. Until this thread there was no consumer that could violate it, so it held by inspection. There is one now.

The fence is project-wide and AST-based: no `%Riffle.Ctx{... | ...}` update expression exists anywhere in `lib/` outside `Riffle.Ctx.Knot`. Update syntax is distinguishable in the AST from construction and from pattern matching -- it is the form carrying `|` inside the map -- so the fence catches reaching in without objecting to `%Ctx{} = ctx` in a function head.

### DD-6 -- The layer swallows nothing

D9 in the ledger: the source layer rescued _all_ exceptions into a single opaque tag with debug-only logging. The pattern layer contains no `rescue`, `catch` or `after` at all, fenced over its AST, and an exception raised inside predicate evaluation propagates out of a run with its type and message intact.

The engine's `Loader` does convert raises to tagged errors, and that stays: `.pred` content is user input and the conversion happens at exactly that boundary, scoped to the one failure it names. The distinction the fence encodes is between converting a known failure at a boundary and swallowing everything everywhere.

### DD-7 -- `ctx.input` holds the ingested items, not the raw input

Ingest is total over its declared input -- an enumerable of field maps or `Item` structs -- and loud outside it. It runs before the first perturbation, so a bad input shape raises before anything is half-recorded.

The run records the _post_-ingest items as its input. That makes a run replayable from `ctx.input` alone: feed those items back and the same output follows, with no need to re-run ingest and no chance of ingest drifting between the original and the replay. Recording the raw maps instead would make `input` and `output` symmetric-looking while making replay depend on a conversion that is not itself recorded.

This is what hv's "CSV datasource out, replaced by plain ingest" means concretely: there is no datasource abstraction, no reader, no format. A caller with a CSV converts it and hands over rows.

### DD-8 -- The pipeline source vocabulary is closed

Four shapes, and nothing else: a `Pipeline` struct, `{:module, module}`, `{:file, path}`, `:default_module`. Anything else raises naming what arrived.

`.pred` files are in, per hv's ratified call: the loader is built, tested and green from ST0001, and excluding it would leave working code unreachable. `:default_module` resolves through `config :riffle, :default_pipeline` -- configuration injection, which is what severing the stitch replaced the hardcoded reference with, so exercising it is also exercising the sever.

An unresolvable source is a _typed run failure_, not a raise: a missing file or an absent pipeline name is user input, and the run records `:failed`, accumulates the reason, and emits `ErrorRaised`. A source outside the vocabulary is a programming error and raises. The line between them is whether a correct program could produce it.

### DD-9 -- The fence helpers and the boundary fence move up a level

`Riffle.WaistHelpers` becomes `Riffle.FenceHelpers`, and `test/riffle/ctx/boundary_fence_test.exs` becomes `test/riffle/boundary_fence_test.exs`.

Both were already project-level despite their names -- the boundary fence has asserted things about the engine since ST0002, which is not a waist concern. Adding two more namespaces to a file whose path says `ctx/` would file the pattern-layer invariants where nobody looks for them, and putting `sia_namespace/0` into a module called `WaistHelpers` would make the Highlander registry entry a lie. The alternative -- a second helper module for the SIA fences -- duplicates the AST walk, which is the drift the original consolidation existed to prevent.

### DD-10 -- What was deliberately not built

- **No datasource layer.** hv's ruling. A fan-in source is a natural later addition that would then genuinely prove source independence; adding one now would prove nothing.
- **No stage registry or stage behaviour.** DD-2 makes the loop the stage. A registry would be a mechanism with one consumer.
- **No results store, cache or run log.** Emissions are transient by bedrock commitment 5. A consumer that wants a log keeps one.
- **No `Riffle.Sia.process/2` compatibility shape.** The source layer's entry point took a context and returned a context, hiding the emissions entirely. Returning `{ctx, emissions}` is what makes DD-3 checkable.
- **No rescue-based error tagging in the layer.** DD-6.

## Architecture

```
raw input --> [ ingest ]                                Riffle.Sia (the edge)
                 |
                 v
            RunStarted -> InputReceived --------------> Riffle.Ctx.Knot.tick/2 --> emissions
                 |                                            ^      |
                 |   for each loop, in order:                 |      |
                 |     StageEntered ----------------------->  |      |
                 |     ( Loop.filter -- Riffle.Predicate )    |      v
                 |     StageProgressed --------------------> tick   ctx'
                 |     StageExited ------------------------>  |
                 v                                            |
            RunCompleted ------------------------------------>+
                 |
                 v
          {ctx, [emission]}
```

The engine appears once, in the parenthesised step: evaluating a loop against the surviving items. That call is impure -- it reaches the cache -- and it happens strictly between two `tick/2` calls, never inside one.

## Alternatives Considered

**Calling `Pipeline.process/2` once instead of staging loop by loop.** One call, and the engine already sequences the loops. Rejected: the run would have exactly one observable step, so `StageEntered`/`StageProgressed`/`StageExited` would have no consumer and the three stage types in the waist would be dead. Staging is the only thing the pattern layer adds over calling the engine directly -- without it there is no layer, just a wrapper.

**Recording raw input and deriving items per stage.** Rejected under DD-7: replay would depend on an unrecorded conversion.

**A `results_available`-style completion flag, kept honest by a fence.** Rejected. A flag whose truth needs a fence is a flag that should not exist; the presence of the results is the fact.

**Tagging stages by prefix convention (`signal_`, `inference_`, `action_`).** Rejected under DD-2: it would make the layer parse names it does not own, and break silently for any pipeline that did not adopt the convention.
