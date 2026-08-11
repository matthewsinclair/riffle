---
verblock: "11 Aug 2026:v0.1: cc - Contract authored against hv's architecture ruling, before any code"
st_id: ST0004
title: "The CLI: a thin coordinator over a service module -- acceptance contract"
---

# ST0004 The CLI -- Acceptance

> Canonical acceptance contract for ST0004. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them. Real test code lives in the suite (paths cited below); this file is the contract plus the AC-to-AT coverage map plus live status. info.md / WP info.md reference this file and never restate ACs (one home).
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Change control: clarifying an AC or AT is verifier-and-builder; shrinking scope, or weakening an AT to make it pass, needs the owner.
>
> AT status vocabulary: to-write (red-first) | red | green | n/a (non-test: doc / eyeball / gate).
>
> Non-test ACs carry their state inline -- `-- evidence: <ref> -- satisfied: yes|no` on the AC line; test-backed ACs are satisfied by a green covering AT (computed, never written). Multi-AC coverage on an AT is comma-separated.
>
> What this contract is shaped by. Three things, all settled before it was written. **hv's architecture ruling (2026-08-11)**: a service module holds the business logic, and the CLI and the mix task are both thin coordinators over it -- so thin-ness is the thing this thread must prove, not merely assert. **arca_cli is the CLI framework and its features are to be used**: the archived layer wrapped it in a 1198-line local `CommandBase` and hand-rolled formatting, error handling and outcome that the framework already provides; none of that is rebuilt here. **The archived CLI reconstructed stage identity by parsing tag prefixes** (`signal_`, `inference_`, `action_`) into fixed output columns, which contradicts ST0003 DD-2 (a stage is a loop, and its identity is the loop's own name) and would make the README's "a pipeline with four loops runs as four stages with no code change" false at the command line. AC-01.2 exists to make that class of defect impossible rather than absent.

## Acceptance Criteria

### ST-level

- AC-00.1 (non-test) `mix gate` green at close -- format, compile and test both under warnings-as-errors, `credo --strict` -- evidence: impl.md Gate section -- satisfied: no
- AC-00.2 (non-test) Every fence this thread adds is mutation-checked: break the thing it guards, watch it go red, restore. A fence that cannot fail is not a fence -- evidence: impl.md mutation table -- satisfied: no
- AC-00.3 (non-test) Every module created is registered in `intent/llm/MODULES.md` before its file exists -- evidence: MODULES.md rows for the service layer, the CLI layer and the mix task -- satisfied: no

### WP-01 -- The service module and its input (status: WIP)

- AC-01.1 One service entry point runs a pipeline over rows read from a file and returns a typed result carrying the run context, its emissions, and a summary. Every caller -- CLI, mix task, or a future one -- reaches the system through it and through nothing else
- AC-01.2 The summary names exactly the loops the pipeline declares, in declaration order, by their own names, and is computed from the run's own stage evidence. Proven over a pipeline of four loops whose names follow no convention: a four-loop pipeline summarises as four stages under those four names, with no code change and no naming convention parsed out of tags
- AC-01.3 The service names no CLI-framework module at any depth: the library remains usable, and its tests remain runnable, by a caller that never loads `Arca`. The CLI dependency is contained above the service, not threaded through it
- AC-01.4 Every failure a correct caller can provoke is a tagged error naming what went wrong -- input file absent, input file unreadable, input carrying no data rows, pipeline source absent, pipeline name not present in the source -- and none of them is a silent empty result or a run reported as successful
- AC-01.5 The service swallows nothing: every `rescue` in the service layer names a specific exception type, no `rescue`-all or bare `catch`/`after` exists anywhere in it, and an exception raised inside predicate evaluation propagates out of the service unchanged. (Clarified before building, 2026-08-11: the first draft said "contains no `rescue`, `catch` or `after`" outright, which is not what the layer can honestly promise -- reading a user-supplied CSV is a user-input boundary where a parse failure must become a tagged error, exactly as `Riffle.Predicate.Dsl.Loader` already does for `.pred` text. Forbidding the rescue-all while requiring every rescue to name its type is both provable and stricter than the prose version, because it fences the shape that actually caused D9 rather than the keyword)
- AC-01.6 Reading input is total over its declared form and loud outside it: a CSV whose first row is a header becomes one field map per data row keyed by that header, values carried as read; a file whose header row is absent or whose rows do not match the header is a tagged error, never a truncated or padded row

### WP-02 -- The arca_cli command surface (status: WIP)

- AC-02.1 No module under the CLI layer names an engine, waist or pattern-layer module at any depth. The commands reach the system through the service alone -- this is "thin coordinator" stated mechanically rather than asserted in prose
- AC-02.2 Commands are defined and registered through the framework's own surface -- `Arca.Cli.Command.BaseCommand` and a `BaseConfigurator` -- and `handle/3` returns an `Arca.Cli.Ctx`, so command outcome and output rendering are the framework's job. No local base-command, formatter, or outcome machinery is reimplemented
- AC-02.3 Output style is the framework's vocabulary reached through `Arca.Cli.Ctx.parse_style/1`, not a locally-invented format list, and an unrecognised style is refused rather than silently defaulted
- AC-02.4 A run that fails carries its reason into the command context and completes with a non-`:ok` outcome; a run that succeeds completes `:ok`. The exit status a caller sees follows the run, and a failed run never reports success
- AC-02.5 `sia.pipelines` reports the pipelines a source defines, by name, without running one
- AC-02.6 The two context types stay distinct: no CLI module constructs or updates a `Riffle.Ctx`, which belongs to the waist and changes only through the knot

### WP-03 -- Bindings: mix task, escript, devbin, sample (status: WIP)

- AC-03.1 (non-test) `bin/riffle cli` reaches the CLI: the `riffle.cli` mix task exists, and `bin/riffle cli sia.run --help` and `bin/riffle repl` both run -- evidence: impl.md Bindings section -- satisfied: no
- AC-03.2 The mix task is a doorway and nothing more: it names the CLI framework's entry point and no other module, so exactly one argv parser exists in the project
- AC-03.3 (non-test) The escript builds and the resulting binary runs the same commands as the mix task -- evidence: impl.md Bindings section -- satisfied: no
- AC-03.4 (non-test) `bin/.devbin/help/cli.md` is authored, replacing the "No authored detail yet" stub -- evidence: bin/.devbin/help/cli.md -- satisfied: no
- AC-03.5 Riffle ships sample input whose columns match the shipped pipeline definitions: a run of the shipped `.pred` over the shipped sample produces surviving items carrying concrete tags, not an empty result
- AC-03.6 (non-test) The README no longer claims Riffle has no CLI, and shows how to run one -- evidence: README.md Status section -- satisfied: no
- AC-03.7 (non-test) design.md records the decisions with their rationale, including what was deliberately not built -- evidence: intent/st/ST0004/design.md -- satisfied: no
- AC-03.8 (non-test) impl.md records the as-built, the critic rounds and their outcomes, and the mutation table -- evidence: intent/st/ST0004/impl.md -- satisfied: no
- AC-03.9 (non-test) Rule-library conformance at the bar of the three prior threads: `intent critic elixir` review and test-check over every file this thread touched, every CRITICAL and every Highlander WARNING fixed at source, none suppressed -- evidence: impl.md Critic rounds -- satisfied: no
- AC-03.10 (non-test) Zero source-project traces in the new files -- evidence: extrication_gate_test green across the new lib/, priv/, bin/ and test/ files -- satisfied: no

## Acceptance Tests

### WP-01

- AT-01.1 test/riffle/service/service_test.exs -- covers AC-01.1 -- status: to-write
- AT-01.2 test/riffle/service/stage_agnostic_fence_test.exs -- covers AC-01.2 -- status: to-write
- AT-01.3 test/riffle/boundary_fence_test.exs (the service names no CLI-framework module) -- covers AC-01.3 -- status: to-write
- AT-01.4 test/riffle/service/service_test.exs (one per provokable failure) -- covers AC-01.4 -- status: to-write
- AT-01.5 test/riffle/service/no_rescue_fence_test.exs (AST fence over the service, plus a raising predicate propagating out) -- covers AC-01.5 -- status: to-write
- AT-01.6 test/riffle/service/csv_test.exs -- covers AC-01.6 -- status: to-write
- Coverage: complete -- AC-01.1..6 each covered by an AT above.

### WP-02

- AT-02.1 test/riffle/cli/thin_coordinator_fence_test.exs -- covers AC-02.1 -- status: to-write
- AT-02.2 test/riffle/cli/sia_run_command_test.exs -- covers AC-02.2 -- status: to-write
- AT-02.3 test/riffle/cli/sia_run_command_test.exs (style parsing and refusal) -- covers AC-02.3 -- status: to-write
- AT-02.4 test/riffle/cli/sia_run_command_test.exs (outcome follows the run, both directions) -- covers AC-02.4 -- status: to-write
- AT-02.5 test/riffle/cli/sia_pipelines_command_test.exs -- covers AC-02.5 -- status: to-write
- AT-02.6 test/riffle/single_transition_fence_test.exs (already sweeps lib/ minus the waist; the CLI layer inherits it) -- covers AC-02.6 -- status: to-write
- Coverage: complete -- AC-02.1..6 each covered by an AT above.

### WP-03

- AT-03.1 test/riffle/cli/mix_task_test.exs -- covers AC-03.2 -- status: to-write
- AT-03.2 test/riffle/service/sample_test.exs -- covers AC-03.5 -- status: to-write
- Coverage: AC-03.2 and AC-03.5 covered above; AC-03.1, AC-03.3, AC-03.4 and AC-03.6..10 are non-test, with evidence inline.
