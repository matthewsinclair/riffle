---
verblock: "10 Aug 2026:v0.2: cc - Restart context after WP-04 c1..c10 + R4a"
---

# Restart Context

## Where things stand (2026-08-10, localfold #2)

ST0001 WP-01..03 DONE. WP-04 is ~90% done: socrates design pass (DD-9), the Resolver, all five call-site reroutes, one evaluation entry point, STD twin removal, silent-drop raises, expr-family consolidation, strict Coerce (DD-8), and critic remediation R4a are all landed -- twelve gate-green commits today (c022e46..d8cac87). Suite: 282 green under `mix gate`. CI green on GitHub (first Actions run 23s). hv rulings applied: coercion strict; push authorised ("push away").

## Next unit of work: WP-04 R4b, then close

1. **R4b -- extraction-ladder dedup (last Highlander WARNING):** new `Riffle.Predicate.Dsl.Statements` module owning the DSL statement-shape ladder (`block_statements/1`, `predicates!/2`, `loops!/3` with context-parameterised raise messages). Consumed by `Dsl.Macro` (contexts "defloop"/"defpipeline") and `Dsl.Parser` (contexts "a loop block"/"a pipeline block"); existing raise-message test pins must keep passing verbatim. Drop the DEAD expr-specific clauses in both ladders (shadowed by the generic `[do: body]` clauses; `Predicate.create/1`'s raw `{:expr, meta, [expr]}` head is the real normaliser). Tighten parser's unguarded name clauses to `is_atom` (macro already guards).
2. **R4b -- loader top-level completeness pass (downgraded CODE-005):** in `Loader.load_string/1` after parse, reject any top-level statement that is not predicate/loop/pipeline/alias -> ArgumentError -> `{:invalid_dsl, message}` via the existing rescue. Red-first test: top-level `predicat(:x) do ... end` currently vanishes silently.
3. **Verify AC-04.2:** targeted critic re-check on the touched files (macro.ex, parser.ex, loader.ex) or full re-run; bar = zero CRITICAL, zero Highlander/PFIC WARNINGs. Update acceptance.md AC-04.2 evidence to satisfied.
4. **Close:** `intent wp done ST0001/04` (close-gate reads acceptance.md), `intent todo update`, refresh intent/wip.md + board, fold commit, push both remotes (`git push local main && git push upstream main`), check `gh run list -R matthewsinclair/riffle`.

## Open items for hv

None blocking. FYI backlog filed (DD-9 + impl.md): Cache perf follow-up (GenServer call per lookup -- unify-then-fix verdict from the socrates pass); socrates handoff on the Macro/DefaultPipelineConfig accessor split; diogenes test-spec pass suite-wide; cache keys not source-qualified (documented).

## Read before touching the engine

- `intent/st/ST0001/design.md` -- DD-1..DD-9 (DD-9 = resolver design + follow-ups; DD-8 = strict coercion as-built)
- `intent/st/ST0001/impl.md` -- as-built incl. WP-04 c1..c10 + critic reports + R4a/R4b split
- `intent/st/ST0001/acceptance.md` -- AC/AT map (AC-04.2 is the only open item)
- `intent/whiteboard/cc/wip.md` -- live node board (paused at localfold)
- `intent/llm/MODULES.md` -- populated registry (Resolver, Coerce et al)

## Invariants (do not regress)

- Zero source-project traces in `lib/` + `test/` -- `test/riffle/extrication_gate_test.exs` enforces structurally
- The engine never names a pattern-layer module -- resolution via `config :riffle, :default_pipeline` inside the Resolver only; unresolvable references raise `UnresolvedPredicateError`
- One resolution path (Resolver), one evaluation entry point (Loop.process), one coercion contract (Coerce, strict) -- do not add parallel paths
- `mix gate` green before every commit; warnings-as-errors covers test compilation
- Archive (`~/Devel/_Archive/Multiplyer`) is read-only forensics
