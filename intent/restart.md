---
verblock: "11 Aug 2026:v0.7: cc - All five threads closed; the project is done to its charter and the queue is empty"
---

# Restart Context

## Where things stand (2026-08-11)

**The project is done to its charter.** ST0001 (the Predicate engine), ST0002 (the Bowtie waist), ST0003 (the SIA pattern layer), ST0004 (the service and the CLI) and ST0005 (documentation) are all closed, gates 11/11, 17/17, 22/22, 26/26 and 17/17. `mix gate` is green -- 484 passed (90 doctests, 394 tests), 790 mods/funs, zero credo findings, and zero critic findings at any severity across all 108 files. `mix docs` is clean at zero warnings. CI runs the same alias.

**There is nothing queued.** What comes next is a decision, not a continuation -- see "Where to go next" below.

## Read these first

- `intent/docs/bedrock.md` -- **the architectural commitments**, eleven of them, each bound to the fence that holds it. A contradiction with this document is a bug in the contradicting document, not a choice. Read it before writing any code.
- `README.md` -- what Riffle is, the shape, how to run it, and a routing table to everything else.
- `intent/wip.md` -- the state of play, the backlog, and what each backlog item is waiting on.
- `docs/pred-language.md` -- the `.pred` language: definition forms, the expression language, the standard library. Every snippet in it is checked by the loader and every expression by the evaluator.
- `intent/st/COMPLETED/ST0005/{design,impl}.md` -- the documentation discipline, DD-1..DD-10. `ST0004/` -- the service and the CLI. `ST0003/` -- the pattern layer. `ST0002/` -- the waist. `ST0001/` -- the engine.
- `intent/llm/MODULES.md` -- the Highlander registry, covering all five layers and the test-support modules.

## The shape, in one line

Five layers, each naming the one below it and named by none of them. Every clause of that is held by a fence.

```
argv --> Riffle.Cli (thin: parse, one call, render)
             |
             v
         Riffle.Service (the way in: rows in, a Result out; names no CLI framework)
             |
             v
         Riffle.Sia (the edge)  -->  {ctx, emissions}
             |          |
             |          +--> Riffle.Ctx.Knot.tick/2   (pure, total, the only transition)
             +--> Riffle.Predicate.Loop.filter/2      (impure: cache behind a process)
```

`Riffle.Sia.run(ctx, source, input, opts)` stages a pipeline one loop at a time -- a stage _is_ a loop, and its identity is the loop's own name. The impure evaluation happens strictly between two `tick/2` calls, never inside one. `Riffle.Service.run/1` is one level up and is where every caller enters; the CLI, the mix task and the escript are three doorways onto one argv parser and one service.

## Where to go next

**Nothing is queued and no thread is open. The next unit is a decision.** Bring the candidates and the reasoning; do not pick one and start.

`intent/wip.md` lays out three, with the argument for each -- a second consumer, publishing, or one of streaming/persistence/a datasource layer. A second consumer would still teach the most, though ST0004 was already a partial version of that experiment and the separation held: the whole CLI was built without naming the engine, the waist or the pattern layer once.

Publishing is the one with an external blocker rather than an open question: `arca_cli` and `arca_config` are GitHub dependencies, so `mix hex.publish` cannot take Riffle while the CLI is a runtime dependency. hv has moving them to hex on the plan, and Riffle unblocks with it.

Worth putting on the table alongside those: the backlog has four items waiting on an hv ruling, and two of them (the perturbation/emission structural twins, and one error vocabulary at the loader boundary) are small enough to clear in a session if hv would rather bank tidy-up than open new ground.

## Invariants (do not regress)

- Zero source-project traces in `lib/` + `test/` -- `extrication_gate_test.exs` enforces structurally; `intent/` and the README are the declared exception
- The five layers name each other only in the one permitted direction -- `boundary_fence_test.exs` (AST-based, engine/waist/pattern layer/service) and `cli/thin_coordinator_fence_test.exs` (the CLI reaches only the service)
- One argv parser -- `cli/mix_task_test.exs`: the mix task names the framework and no Riffle module at all
- The knot stays unconditionally pure -- `purity_fence_test.exs` walks the compiled call closure
- The knot is the only transition -- `single_transition_fence_test.exs`, both spellings of update syntax
- Every perturbation yields a real emission, never the delivery floor -- `delivery_floor_fence_test.exs`
- No derived claim outlives its evidence -- `sia/evidence_fence_test.exs`, over a declared matrix of run shapes
- A stage is a loop, and the count is whatever the pipeline declares -- `service/stage_agnostic_fence_test.exs`
- Nothing swallows -- `sia/no_rescue_fence_test.exs` (none at all in the pattern layer) and `service/no_rescue_fence_test.exs` (every rescue names its type at the user-input boundary)
- Documentation claims are checked -- `docs/doc_conformance_test.exs` and `docs/pred_reference_test.exs`
- A fence that cannot fail is not a fence: mutation-check every new one, and give it a positive control when its discriminator would otherwise never fire. Across five threads, mutation testing has repeatedly caught the _test estate_ rather than the code
- `mix gate` green before every commit; it includes `credo --strict`, and warnings-as-errors covers test compilation
- Archive (`~/Devel/_Archive/Multiplyer`) is read-only forensics
