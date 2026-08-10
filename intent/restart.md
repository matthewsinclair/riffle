---
verblock: "10 Aug 2026:v0.3: cc - Restart context after ST0001 close"
---

# Restart Context

## Where things stand (2026-08-10, ST0001 closed)

ST0001 "Extricate Predicate and SIA from Multiplyer" is CLOSED -- gate 11/11 satisfied, docs under `intent/st/COMPLETED/ST0001/`. Fourteen gate-green engine commits today (c022e46..7c3c940): Resolver (DD-9) as THE resolution+hydration path, one cached evaluation entry point, strict Coerce (DD-8), `Dsl.Statements` as THE block grammar, one top-level parser dispatch (completeness by construction), and the STD surface made real (R4b's strengthened critic test exposed `call` syntax as having no handler at all -- `Predicate.create/1` now owns the `{:call, ...}` head and `expand_std/1`, a pure AST prewalk). Suite: 286 green under `mix gate`, zero warnings, credo delta from cc's work: -1.

Peer-session commits on main (hv-driven, not cc's): 026310b (bin/riffle launcher), fb3e34a (credo + fleet .credo.exs). The 21 remaining credo baseline findings belong to that cleanup workstream.

## Next unit of work

ST0002 (ctx-next, the Bowtie waist) -- **needs hv assignment and plan ratification before any code**. ST0003 (SIA rewrite) queued behind it; its D2 obligations (deliver results via emissions; no lying availability flag) are recorded in ST0001 design.md.

## Open items for hv

- ST0002 kickoff: scope + plan ratification.
- Backlog to schedule or decline: Cache perf (persistent_term + ets counters); two socrates handoffs (Macro/DefaultPipelineConfig accessor split; single definition-argument recogniser in Dsl.Statements); loader error-vocabulary unification (public contract change); diogenes spec pass; cache key source-qualification.

## Read before touching the engine

- `intent/st/COMPLETED/ST0001/design.md` -- DD-1..DD-9
- `intent/st/COMPLETED/ST0001/impl.md` -- as-built incl. every critic report and the R4a/R4b remediations
- `intent/llm/MODULES.md` -- populated registry (Resolver, Coerce, Statements et al)
- `intent/whiteboard/cc/wip.md` -- live node board

## Invariants (do not regress)

- Zero source-project traces in `lib/` + `test/` -- `test/riffle/extrication_gate_test.exs` enforces structurally
- The engine never names a pattern-layer module -- resolution via `config :riffle, :default_pipeline` inside the Resolver only; unresolvable references raise `UnresolvedPredicateError`
- One resolution path (Resolver), one evaluation entry point (Loop.process), one coercion contract (Coerce, strict), one DSL block grammar (Dsl.Statements), one top-level dispatch (Parser.extract_definitions!) -- do not add parallel paths
- `mix gate` green before every commit; warnings-as-errors covers test compilation
- Archive (`~/Devel/_Archive/Multiplyer`) is read-only forensics
