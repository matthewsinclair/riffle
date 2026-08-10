---
verblock: "10 Aug 2026:v0.4: cc - Restart context at localfold #3; ST0002 + ST0003 next"
---

# Restart Context

## Where things stand (2026-08-10, localfold #3)

ST0001 "Extricate Predicate and SIA from Multiplyer" is CLOSED -- gate 11/11, docs under `intent/st/COMPLETED/ST0001/`. The Predicate engine is extricated, PFIC-transformed, critic-clean and credo-clean. Seventeen commits pushed to both remotes today, CI green on every one.

Toolchain state worth knowing before the next commit: `mix gate` is now format + compile + test + `credo --strict`, and CI runs that same alias, so a new credo finding fails the build locally and upstream. `main` is branch-protected (required check `gate`, strict, no force-push, no deletion, `enforce_admins: false` -- direct pushes still work and are logged as bypasses). No CD by decision; devbin has no `release`, and its `publish` opt-in stays off until Riffle is more than the engine half.

## Next unit of work: ST0002, then ST0003

hv sequenced both (2026-08-10): ST0002 first, ST0003 after -- ST0003 is blocked on the waist by its own info.md.

**ST0002 (ctx-next, the Bowtie waist).** A REBUILD to the published spec (The Bowtie Pattern, Sinclair Feb 2026), explicitly not a port: typed perturbations fan in, a pure knot `f(P, S) -> (E, S')` runs against immutable state, typed emissions fan out to registered consumers. The archive's `Ctx` (18-field god-struct, 76 public functions, 5,964 LOC across 13 files) is the pattern's earliest incarnation and is deliberately NOT carried over. The minimum surface is measured, not guessed: the 24 Ctx functions the extricated code actually consumes, by call-site count, in `intent/docs/extrication-handoff.md` -- dominated by status transitions, metadata, event lifecycle, error accumulation, and input/output/cargo access. Serve that surface through the typed model; do not replicate the bag-of-maps API shape.

First act at kickoff, before any code: `intent/st/ST0002/acceptance.md` is still the unfilled template. Author the AC/AT contract and get hv's ratification -- the close-gate is fail-by-default, so no WP can close against an empty contract. Then WP breakdown via `intent wp new`.

**ST0003 (SIA pattern layer rewrite).** Red-first against ctx-next. The archive's `sia/` (1.2k LOC) is reference material only: its `.pred` loading is dead by design (D1, unconditional `{:error, :invalid_pipeline_format}`) and its rescue-all swallow (D9) must NOT reproduce. The five characterisation tests pinned at `assert [] = results` become this thread's ATs, strengthened to `assert [%Item{} | _] = results`. Scope decisions this thread owns: whether `.pred` file pipelines return (vs module-defined only, initially), and whether the CSV datasource ports or a cleaner ingest boundary replaces it. D2's obligation: results must be delivered via emissions, with no lying availability flag.

## Open items for hv

- ST0002 scope + acceptance ratification at kickoff (the gate needs it).
- Backlog to schedule or decline: Cache perf (persistent_term + ets counters, DD-9/M4); two socrates handoffs (Macro/DefaultPipelineConfig accessor split; a single definition-argument recogniser in Dsl.Statements); loader error-vocabulary unification (public contract change); diogenes spec pass.

## Read before touching the engine

- `intent/st/COMPLETED/ST0001/design.md` -- DD-1..DD-9
- `intent/st/COMPLETED/ST0001/impl.md` -- as-built incl. every critic report, R4a/R4b, and the post-close credo addendum
- `intent/docs/extrication-handoff.md` -- the measured Ctx surface, defect ledger, and the stitch that must not re-form
- `intent/llm/MODULES.md` -- populated registry (Resolver, Coerce, Statements et al)
- `intent/whiteboard/cc/wip.md` -- live node board

## Invariants (do not regress)

- Zero source-project traces in `lib/` + `test/` -- `test/riffle/extrication_gate_test.exs` enforces structurally
- The engine never names a pattern-layer module -- dependency inversion holds in the rebuild too; ST0003 consumes the engine, never the reverse
- One resolution path (Resolver), one evaluation entry point (Loop.process), one coercion contract (Coerce, strict), one DSL block grammar (Dsl.Statements), one top-level dispatch (Parser.extract_definitions!) -- do not add parallel paths
- `mix gate` green before every commit; it now includes credo, and warnings-as-errors covers test compilation
- Archive (`~/Devel/_Archive/Multiplyer`) is read-only forensics
