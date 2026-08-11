---
verblock: "11 Aug 2026:v0.1: cc - WP-01 as-built, findings and mutation table"
st_id: ST0005
title: "Documentation -- implementation"
---

# ST0005 Documentation -- Implementation

## WP-01 -- The moduledoc pass

### What the survey found before any of it was written

All 61 modules, measured rather than guessed:

| Measure | Before | After |
| ----------------------------------- | --------- | --------- |
| Doctests | 69 | 90 |
| Modules with examples nothing ran | 5 (44 lines) | 0 |
| Undocumented public functions | 15 | 2 (both from arca's configurator) |
| Catalog structs at two-line docs | 20 | 0 |
| Unresolvable `fun/arity` references | 4 | 0 |

The apparent gap was much larger at first reading -- 124 undocumented public functions -- and 109 of those turned out to be `@doc false` or generated and correctly hidden. Reporting the raw number would have made the work look like coverage when it was accuracy.

### The accuracy findings

**The root moduledoc taught a refuted model.** `Riffle` -- the module named after the project, the first page ex_doc renders -- described "three tag-driven stages" identified by `signal_` / `inference_` / `action_` prefixes. ST0003 DD-2 settled that a stage is a loop and that its identity is the loop's own name; ST0004 DD-7 fenced that model out of the CLI. The README had been corrected, `bedrock.md` was right, and the fences enforced the correct model. The moduledoc taught the wrong one regardless, which is the same shape as ST0002's "reference implementation" claim surviving in the README: a ruling applied in most places, not all.

**Five modules carried examples that no `doctest` declaration ran** -- `Riffle.Ctx`, `Riffle.Ctx.Knot`, `Riffle.Predicate.Cache`, `Riffle.Predicate.Dsl.Evaluator` and `Riffle.Service`, 44 lines between them. Three were wrong:

- `Cache.start_link/1` documented `{:ok, _pid} = start_link()`, for a process `Riffle.Application` has already started. False from the moment the supervisor booted.
- `Cache.get/2` and `put/3` referenced undefined variables -- pseudo-code that had never compiled.
- `Evaluator` used `quote do: X end`, which is a syntax error; the `do:` keyword form takes no `end`.
- `Evaluator`'s `@field` examples used `Kernel.SpecialForms.quote/2`, whose hygiene context defeats the shorthand. The evaluator recognises a bare `@name` -- a variable with `nil` context -- which is what `.pred` text and `parse/1`'s string clause produce, and what quoting inside a module does not. The documented usage of the shorthand could not work.
- `Evaluator`'s moduledoc showed calls with backticks used as string delimiters, which is not Elixir at all.

**Four `fun/arity` references did not resolve** -- cross-module references written unqualified (`fetch_by_tag/1`, `get_predicate/1` and friends). They read as prose and would render as broken links.

### The richness findings

The twenty perturbation and emission structs are the public vocabulary of the waist, and each had a one-line moduledoc. Each now states what it means, what its payload carries, and how it relates to its counterpart across the knot -- including the `StageProgress` / `StageCompleted` distinction, which is exactly the distinction the D2 defect turned on.

The DSL macro generated one public accessor per predicate, loop and pipeline with no `@doc`, so `Riffle.Sia.DefaultPipeline`'s page was thirteen bare entries. Each accessor now carries the definition's own description. `@doc false` was the other option and was rejected: these are real API -- a caller reaches a definition by name through them -- so hiding them would be a lie of omission.

### Mutation table

| # | Mutation | Fence | Result |
| --- | ----------------------------------------------------- | ------------------------------- | ------ |
| M1 | a doc gains a reference to a function that does not exist | references resolve | red |
| M2 | the root moduledoc returns to the tag-prefix model | no doc teaches tag-prefix stages | red |
| M3 | a catalog member loses one field's description | catalog members describe fields | red |
| M4 | a `doctest` declaration removed, examples unchecked | examples are checked examples | red |
| M5 | generated accessors stop carrying their description | generated API is documented API | red |

Two fences reported this thread's own work while it was being written: the field-description fence caught a `stage` field left undescribed in a doc written minutes earlier, and the reference fence caught `` `quote/1` `` written unqualified in new prose. A third caught `Riffle.DocHelpers` itself -- its `@doc` mentions `iex>` while describing what it counts, which is what tightened the rule from "contains a prompt" to "begins with one".

### Critic

One round. Seven `IN-EX-TEST-005` warnings for `case` expressions in the fence file's helpers. Fixed as a Highlander problem rather than locally: the walks moved to `Riffle.DocHelpers` in `test/support`, which `mix.exs` already declares as ordinary Elixir where branching is allowed, and which WP-03's `.pred` reference checks will reuse. Clean at every severity across 107 files afterwards.

### Gate

475 passed (90 doctests, 385 tests), 776 mods/funs, zero credo findings.
