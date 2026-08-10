# Extrication handoff: Multiplyer -> Riffle

**Written 2026-08-10 by the Multiplyer ST0042 triage session. Read this before touching anything.**

Source repo: `~/Devel/_Archive/Multiplyer` (post-archive). It is a fully runnable repo -- `mix test` green at archive point (1049 passed, 4 skipped), Elixir 1.20.3 / OTP 29 -- and its git history is intact. Read-only forensics there are fine; **no new work lands in its history**. The complete triage record (system map, defect ledger D1-D13, hv rulings) is in `_Archive/Multiplyer/intent/st/ST0042/`.

## Mission

Riffle = the SIA sense->infer->act pattern + the Predicate engine, extricated from Multiplyer, on a context waist (`ctx-next`) rebuilt to The Bowtie Pattern (Sinclair, Feb 2026; canonical doc: Lamplight `docs/external/whitepapers/bowtie/the_bowtie_pattern.md`). Riffle is intended as the pattern's open-source reference implementation.

## Bill of materials

| Multiplyer asset                     | LOC    | Disposition                                                                              |
| ------------------------------------ | ------ | ---------------------------------------------------------------------------------------- |
| `lib/multiplyer/predicate/` (15 files) | 5,136 | **PORT nearly as-is, with its tests.** The engine is the asset. See stitches below.      |
| `lib/multiplyer/sia/` (3 files + `sia.pred`) | 1,227 | **Reference material only** -- rewritten red-first in ST0003. Do not graft verbatim.     |
| `lib/multiplyer/ctx/` (13 files)     | 5,964  | **NOT ported.** ctx-next is rebuilt to the Bowtie spec (ST0002). See measured surface.   |
| `lib/multiplyer/datasource/` (csv, generator) | 1,251 | **Optional, decide in ST0003** -- useful for examples; or replace with a cleaner ingest boundary. |
| `lib/multiplyer/ta2/` (54 files)     | 13,542 | **Stays behind** (retired: superseded by state of the art). Preserved-ideas note below.  |
| `lib/multiplyer/cli/`, `config/`, `registry/`, `utils/` | ~9,100 | **Stays behind.** Riffle grows its own thin CLI later if wanted.                         |

Preserved-ideas note (TA2): its fixture-based mock-LLM testing harness (`ta2/testing/`) and schema-centric parameter registry (`ta2/schema/`) were ahead of their time; if Riffle ever needs either shape, read them in the archive -- do not pre-import.

## Measured dependency facts (2026-08-10, grep of module references)

- **Predicate is Ctx-free**: zero `Ctx` call sites in `lib/multiplyer/predicate/`. The engine ports pure.
- TA2 never references Sia or Predicate (any direction, static or dynamic; `priv/` catalog definitions clean too) -- the extraction has no TA2 entanglement.
- The Ctx consumers are SIA glue (15 refs) and datasource (15 refs) only.
- CLI referenced Ctx 89x / Sia 3x / Predicate 3x -- none of it comes along.

## Stitches to sever (all verified at file:line in the source)

1. **predicate -> sia fallback** (the one stitch INSIDE ported code): `predicate/pipeline.ex:138,182` and `predicate/loop.ex:205-208` hardcode `Multiplyer.Sia.DefaultPipeline` as a `Code.ensure_loaded?`-guarded fallback, and `predicate/dsl/macro.ex:94` references it in comment. Sever at port: the engine must never reference the pattern layer. Replace with injected/config default-pipeline resolution. **This stitch must not re-form in Riffle.**
2. **ctx -> predicate**: `ctx/formatter/json.ex:228` pattern-matches `%Multiplyer.Predicate.Item{}` in `sanitize_value/1`. Dies with Ctx; in ctx-next, emission encoding must not special-case engine types (protocol instead).
3. **registry -> ta2**: `registry/supervisor.ex:15` supervises `Ta2.Schema.Registry`. Stays behind entirely.

## The measured ctx-next contract (what the extricated code actually consumes)

Call-site counts across `sia/` + `datasource/` (predicate: zero). Serve these THROUGH the typed perturbation/emission model -- do not replicate the bag API:

```
34 Ctx.t (typespecs)            8 Ctx.add_error            4 Ctx.get_input
17 Ctx.with_status              6 Ctx.set_input            3 Ctx.record_event
14 Ctx.set_metadata_value       5 Ctx.with_inputs          3 Ctx.has_errors?
12 Ctx.new                      5 Ctx.set_cargo_item       2 Ctx.get_output
11 Ctx.debug                    5 Ctx.event_started        2 Ctx.complete
 8 Ctx.event_completed          4 Ctx.set_output           1 each: verbose?, set_opt,
 4 Ctx.log                      1 Ctx.event_progress         get_metadata, get_cargo_item,
                                                             Ctx.Stats.get_all_stats
```

Shape summary: status transitions, metadata, event lifecycle (started/completed/progress), error accumulation, input/output/cargo access, debug/log emission, one stats read.

## Defect ledger subset that matters here (full ledger: ST0042 design.md, D1-D13)

- **D2 -- OPEN, root-cause FIRST (ST0001's first task):** `Sia.process(ctx, :default_module)` yields `[]`; five characterisation tests in `test/multiplyer/sia/sia_pipeline_test.exs` pin `assert [] = results` deliberately. The pre-compiled `DefaultPipeline.get_pipeline/1` path should work and does not. Diagnosis protocol: run those tests in the archive; trace `sia.ex` `process/4` -> `prepare_data/1` -> `load_pipeline/2` (`:default_module` branch, `sia.ex:149-152`) -> `execute_sia_pipeline/3`; find which step produces the empty set. **Verdict required: does the defect live in Predicate (travels with the port) or SIA glue (dies in rewrite)?**
- **D1 -- dead by design, do not "fix" by porting:** `.pred` file loading returns `{:error, :invalid_pipeline_format}` unconditionally (`sia.ex:154-179`, honest tombstone comment in place; the missing `get_pipeline` step is documented there). ST0003 decides whether `.pred` support returns at all.
- **D9 -- do not reproduce:** `sia.ex:222-237` rescues ALL exceptions into `{:error, :pipeline_execution_error}` with debug-only logging. Riffle surfaces real errors (No Silent Errors).
- **D5 -- fix at port:** Elixir 1.20 type warning in `test/multiplyer/predicate/dsl/expr_macro_direct_test.exs:31` (`Predicate.new/3` arg shape) -- it ports with the engine tests; fix it there, and gate test compilation with warnings-as-errors in Riffle CI from day one.
- **D3 (context only):** Multiplyer's file logging crash-loops under OTP 29 (`logger_file_backend` 0.0.14, unmaintained). Not Riffle's problem -- just do not import that dependency.

## Test estate

- Predicate tests port with the engine (they pass in the archive).
- The 5 SIA characterisation tests become ST0003's red-first ATs, strengthened to `assert [%Item{} | _] = results`.
- Multiplyer's wider suite was only spot-audited; assume weak-assertion density in anything else you consult (evidence: 65 critic findings on migration-touched files alone).
- Riffle test discipline from day one: strong assertions, async by default, no `Process.sleep`, no control flow in tests, mock only at boundaries.

## First moves (suggested order)

1. Read this doc + ST0001/ST0002/ST0003 info.md.
2. D2 root-cause in the archive (protocol above); record the travels-with-Predicate verdict in ST0001.
3. Declare languages (`intent lang init elixir`); set up CI with `--warnings-as-errors` covering test compilation (mix skeleton + MIT licence already in place).
4. Port `predicate/` + its tests; sever stitch 1; fix D5; suite green.
5. ST0002 ctx-next design against the whitepaper + the measured contract.
6. ST0003 rewrite, red-first from the strengthened characterisation tests.

## Provenance

Multiplyer ST0042 "Modernise Multiplyer: salvage, open-source, retire" (2026-08-10): info.md carries the hv rulings record (TA2 retire; SIA+Predicate extract; ctx rebuilt to spec; Multiplyer archived as anecdote); design.md the full system map + defect ledger; impl.md the catalog-cull and baseline record. The name: a riffle is the catching bar in a sluice -- the stream flows through, the gold stays. `sluice` itself is taken on hex by a Gleam stage-pipeline package (checked 2026-08-10); `riffle` was free.
