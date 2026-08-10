# Implementation - ST0002: ctx-next: the Bowtie waist

## As built

Four modules under `lib/riffle/ctx/` plus twenty catalog structs, and seven fence files under `test/riffle/ctx/` sharing one identity helper in `test/support/waist_helpers.ex`.

- `Riffle.Ctx` -- six typed slots (`run_id`, `status`, `input`, `output`, `errors`, `metadata`), one declared overlay, construction and one overlay read. No setters and no pass-through accessors: the typed slots are read by dot.
- `Riffle.Ctx.Knot` -- `tick/2`, multi-clause on the perturbation struct, with the delivery floor as the catch-all's funnel.
- `Riffle.Ctx.Catalog` -- the registry mechanism and the `tag/0` contract, used by both catalogs.
- `Riffle.Ctx.Perturbation` / `Riffle.Ctx.Emission` -- membership and the union type, nothing else.

Commits: `02d74dd` (WP-01), `8df5972` (WP-02), and the WP-03 remediation commit.

## What the compiler proved

Two design assumptions turned out to be enforceable statically rather than by test, and both changed the code.

The delivery floor was written with two reasons -- a perturbation no clause claimed, and a clause that claimed one and emitted nothing. The compiler reports the second clause unreachable, because every `transition/2` clause returns a non-empty list. It was removed rather than suppressed: keeping it would silently repair a future clause that forgot to emit, whereas the delivery-floor fence fails the build and makes someone fix the clause. `DefaultPassed` now carries one reason.

The closed registries are provably non-empty, so two fences' own non-vacuity guards were rejected as always-true comparisons. They were removed with the reasoning recorded inline, because `mix gate` compiles tests under `--warnings-as-errors` -- so the proof fails the build, which is stronger than the guard it replaced.

## Critic remediation

Two rounds. The first review returned 1 CRITICAL and 4 WARNING on `lib/`, and 6 CRITICAL on the tests; the second returned 0 CRITICAL / 3 WARNING and 2 CRITICAL / 3 WARNING respectively. Everything at or above the ratified bar was fixed at source; nothing was suppressed.

**Round one.** `Ctx.new/1` read the two options it knew and discarded the rest, so `metadatra:` was accepted in silence -- the exact bag behaviour the module exists to refuse, in its own constructor (`Keyword.validate!`). `get_metadata/2` returned bare `nil`, which cannot distinguish an absent key from a recorded `nil`; it became `fetch_metadata/2`, matching the catalogs' shape. The two catalog registries were byte-identical scaffolding around different membership lists, with two byte-identical `Kind` behaviours -- a real Highlander violation, collapsed into `Riffle.Ctx.Catalog`, which also moved duplicate-tag detection from test time to compile time. `MODULES.md` named the transition point `apply/2` when the code said `tick/2`.

On the test side, six fences could pass vacuously or asserted tautologies: `length(overlay_slots()) <= 1` admits zero; two tests compared a function to a second call of itself, which proves determinism the purity fence already proves far better while saying nothing about whether the result is right; `function_exported?/3` ran without loading the module, so a `refute` passed for the wrong reason. Each was replaced with a pinned value -- including a golden trajectory for replay.

**Round two.** Two CRITICALs, both real, and the first is the more instructive.

`WaistHelpers.remote_modules/1` matched the Erlang remote-type form with a two-element list. It carries three (module, function, args). Every remote type therefore fell through to the catch-all, `references_catalog?/1` was permanently false, and the DD-6 fence -- no slot accumulates perturbations or emissions -- had been unfalsifiable since it was written. Adding an emission-typed slot would not have failed it. Fixed, and the fence now carries a positive control taken from a real compiled typespec, so it cannot go dead in silence again.

The boundary fence scanned source text for the namespace, which `alias Riffle.{Ctx, Foo}` defeats -- and that brace form is already in the engine's own files. It now walks the parsed AST, which also stops a moduledoc mention from reading as a dependency. It carries a positive control too.

Also from round two: each catalog's membership was written twice in its own file, as the implementations list and again as the `t()` union, with nothing checking they agreed. The union stays hand-written -- a generated one is invisible to a reader and to ExDoc, in a module whose job is a legible typed surface -- and a fence now asserts the two agree. And `get_input/1` / `get_output/1` were pass-through accessors over dot-readable typed slots, which is where a seventy-six-function surface starts; they were deleted, and the measured-surface map now resolves those capabilities to slots.

## Mutation checks

Every fence was broken deliberately and observed to go red, then restored: a registry entry removed; an undeclared bag slot added to the composite root; a knot clause deleted; a `DateTime` call added three frames below the knot; a capability claiming a type that does not exist; a catalog type nothing claims; the type walk's arity broken; a union member dropped. The last two are the checks that would have caught the dead fence above had they been run when it was written.

## Deferred, with reasons

- **Perturbation/emission structural twins** (7 of 10 pairs; 4 transitions are pure renames). A socrates handoff -- whether the bowtie's input/output split earns two parallel catalogs here is a design question, not a mechanical fix.
- **The measured surface has two homes** -- the handoff document and the fence's table, bridged by a hand-typed count. A socrates handoff on whether the fence should parse the document.
- **Test specs** (`.spec.md`) absent for all seven fence files -- a diogenes pass.
- **`Riffle.WaistHelpers` sits in the production root namespace** from `test/support/`, consistent with the existing support modules. Cosmetic; left alone rather than diverging from the established convention.
