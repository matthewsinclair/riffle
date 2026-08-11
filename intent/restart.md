---
verblock: "11 Aug 2026:v0.6: cc - All three threads closed; the extraction is done and the queue is empty"
---

# Restart Context

## Where things stand (2026-08-11)

**The extraction is complete.** ST0001 (the Predicate engine), ST0002 (the Bowtie waist) and ST0003 (the SIA pattern layer) are all closed, gates 11/11, 17/17 and 22/22. `mix gate` is green -- 363 passed, zero credo findings, and zero critic findings at any severity across all 86 files. CI runs the same alias.

**There is nothing queued.** hv's autonomous run reached the end of the work that had been sanctioned. What comes next is a decision, not a continuation -- see "Where to go next" below.

## Read these first

- `intent/docs/bedrock.md` -- **the architectural commitments**, eight of them, each bound to the fence that holds it. A contradiction with this document is a bug in the contradicting document, not a choice. Read it before writing any code.
- `intent/wip.md` -- the state of play, the backlog, and what each backlog item is waiting on.
- `intent/st/COMPLETED/ST0003/{design,impl}.md` -- the pattern layer: DD-1..DD-10, the eleven mutations, and two departures recorded rather than glossed.
- `intent/st/COMPLETED/ST0002/{design,impl}.md` -- the waist. `ST0001/` -- the engine.
- `intent/llm/MODULES.md` -- the Highlander registry, now covering all three parts and the test-support modules.

## The shape, in one line

The engine names nothing. The waist names nothing. The pattern layer names both and is named by neither. Every clause of that is held by a fence, in all four directions.

```
raw rows --> Riffle.Sia (the edge) --> {ctx, emissions}
                |          |
                |          +--> Riffle.Ctx.Knot.tick/2   (pure, total, the only transition)
                +--> Riffle.Predicate.Loop.filter/2      (impure: cache behind a process)
```

`Riffle.Sia.run(ctx, source, input, opts)` stages a pipeline one loop at a time. Each stage is bracketed by perturbations; the impure evaluation happens strictly between two `tick/2` calls, never inside one.

## Where to go next

**hv's instruction on this bounce is to reassess, not to continue.** Nothing is queued, no thread is open, and the next unit is a decision. Bring the candidates and the reasoning; do not pick one and start.

`intent/wip.md` lays out three, with the argument for each -- a second consumer, a thin CLI, or publishing. The first would teach the most: every mechanism in Riffle currently has exactly one consumer, which is the honest reason several were not built, and a second consumer is what would show whether the separation is real or merely declared.

Worth putting on the table alongside them: the backlog below has four items waiting on an hv ruling, and two of those (the perturbation/emission structural twins, and one error vocabulary at the loader boundary) are small enough to clear in a session if hv would rather bank tidy-up than open new ground.

The backlog is filed in `intent/wip.md` with each item labelled by what it is waiting on. Most need an hv ruling; two need a thread of their own; one needs only an agent invocation.

## Invariants (do not regress)

- Zero source-project traces in `lib/` + `test/` -- `extrication_gate_test.exs` enforces structurally; `intent/` and the README are the declared exception
- The engine, the waist and the pattern layer name each other only in the one permitted direction -- `boundary_fence_test.exs`, AST-based, four directions
- The knot stays unconditionally pure -- `purity_fence_test.exs` walks the compiled call closure
- The knot is the only transition -- `single_transition_fence_test.exs`, both spellings of update syntax
- Every perturbation yields a real emission, never the delivery floor -- `delivery_floor_fence_test.exs`
- No derived claim outlives its evidence -- `sia/evidence_fence_test.exs`, over a declared matrix of run shapes
- The pattern layer swallows nothing -- `sia/no_rescue_fence_test.exs`, with positive controls for both AST forms
- A fence that cannot fail is not a fence: mutation-check every new one, and give it a positive control when its discriminator would otherwise never fire. Two threads running, mutation testing has caught the *test estate* rather than the code
- `mix gate` green before every commit; it includes `credo --strict`, and warnings-as-errors covers test compilation
- Archive (`~/Devel/_Archive/Multiplyer`) is read-only forensics
