---
verblock: "11 Aug 2026:v0.2: cc - WP-02 and WP-03 as-built, findings and mutation table"
st_id: ST0005
title: "Documentation -- implementation"
---

# ST0005 Documentation -- Implementation

## WP-01 -- The moduledoc pass

### What the survey found before any of it was written

All 61 modules, measured rather than guessed:

| Measure                             | Before       | After                             |
| ----------------------------------- | ------------ | --------------------------------- |
| Doctests                            | 69           | 90                                |
| Modules with examples nothing ran   | 5 (44 lines) | 0                                 |
| Undocumented public functions       | 15           | 2 (both from arca's configurator) |
| Catalog structs at two-line docs    | 20           | 0                                 |
| Unresolvable `fun/arity` references | 4            | 0                                 |

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

| #   | Mutation                                                  | Fence                            | Result |
| --- | --------------------------------------------------------- | -------------------------------- | ------ |
| M1  | a doc gains a reference to a function that does not exist | references resolve               | red    |
| M2  | the root moduledoc returns to the tag-prefix model        | no doc teaches tag-prefix stages | red    |
| M3  | a catalog member loses one field's description            | catalog members describe fields  | red    |
| M4  | a `doctest` declaration removed, examples unchecked       | examples are checked examples    | red    |
| M5  | generated accessors stop carrying their description       | generated API is documented API  | red    |

Two fences reported this thread's own work while it was being written: the field-description fence caught a `stage` field left undescribed in a doc written minutes earlier, and the reference fence caught `` `quote/1` `` written unqualified in new prose. A third caught `Riffle.DocHelpers` itself -- its `@doc` mentions `iex>` while describing what it counts, which is what tightened the rule from "contains a prompt" to "begins with one".

### Critic

One round. Seven `IN-EX-TEST-005` warnings for `case` expressions in the fence file's helpers. Fixed as a Highlander problem rather than locally: the walks moved to `Riffle.DocHelpers` in `test/support`, which `mix.exs` already declares as ordinary Elixir where branching is allowed, and which WP-03's `.pred` reference checks will reuse. Clean at every severity across 107 files afterwards.

### Gate

475 passed (90 doctests, 385 tests), 776 mods/funs, zero credo findings.

## WP-02 -- ex_doc and the README

### As built

`ex_doc` joins the tree `only: :dev, runtime: false`, so the docs exist and a consumer's dependency set does not change. The whole configuration is `docs/0` in `mix.exs`.

The grouping is the point of it. All 61 modules are placed explicitly across six groups -- `Overview` and the five layers in the order the README gives them -- and the placement was checked by reading the generated sidebar rather than by assuming the config took:

| Group | Modules |
| ---------------------------------- | --- |
| Overview | 1 |
| The engine (`Riffle.Predicate`) | 24 |
| The waist (`Riffle.Ctx`) | 25 |
| The pattern layer (`Riffle.Sia`) | 3 |
| The service (`Riffle.Service`) | 3 |
| The CLI (`Riffle.Cli`) | 4 |

60 in the module section plus `Mix.Tasks.Riffle.Cli`, which `ex_doc` files under its own Mix Tasks heading while still carrying the CLI group label. Nothing landed in a leftover bucket, which was the failure mode worth checking: an unplaced module falls into a trailing `Modules` heading, and that trailing heading is the alphabetical list the grouping exists to replace.

`nest_modules_by_prefix` folds the five families that would otherwise dominate by count -- the ten emissions, the nine perturbations, the DSL, the standard library and the commands.

### What ex_doc found

Two warnings, both real, both fixed rather than silenced.

**The README linked to `LICENSE`, which was not an extra.** The link works in a checkout and on GitHub and was dead in the generated docs. `LICENSE` now rides along as an extra. This is the same class of defect as the language-reference route below, and it is why the route fence exists.

**`Riffle.Predicate.Cache.start_link/1` referenced `Riffle.Application`, which was `@moduledoc false`.** The reference is right -- the paragraph is explaining that a caller never starts the cache because the application already did -- so the module was documented rather than the reference dropped (DD-9). It now states what it supervises, why the caller sees `{:error, {:already_started, pid}}`, and why one child under `:one_for_one` is the right shape for a cache.

`mix docs` is clean at zero warnings.

### The README

It now routes. Added: how to take Riffle as a dependency (and why it is not on hex yet -- `arca_cli` is not either); a `Defining the predicates` section, which was a real hole, since every CLI example in the file passes `--from priv/sia/sia.pred` and nothing said what a `.pred` file is; and a `Where to go next` table pointing at the language reference, the API, the architecture, the extrication charter, the threads and the marks.

Only `docs/pred-language.md` is written as a markdown link, because it is an `ex_doc` extra and therefore resolves in both places. A link to a repository file that is not an extra does not resolve in the generated docs, and `mix docs` says so.

## WP-03 -- The .pred language reference

### The surface it had to cover, measured

| Surface | Count | Source of truth |
| ---------------------------- | ----- | ---------------------------------------- |
| Definition forms | 3 | `Dsl.Parser.bucket_statement/2` |
| Predicate body forms | 3 | `Predicate.create/1` |
| Expression forms | 28 | `Dsl.Evaluator.evaluate/2` clauses |
| Standard-library builders | 29 | the modules, enumerated by the fence |

The builder count is 29 rather than the 25 carried forward from the survey: 25 are in the five category modules and four are the combinators on the parent (`all/1`, `any/1`, `none/1`, `not_pred/1`), which are equally public and equally reachable from a `.pred` body.

All 28 expression forms are documented. Four of them are alternative spellings of a field read (`fields.get("name")`, `fields(["name"])`, `fields[:name]`, and the `@name` shorthand), and they are documented as such rather than promoted -- a reference has to describe the surface as it is, but it does not have to recommend all of it.

### The fences

Three, and they check three different kinds of claim.

**Every `pred` snippet loads and materialises.** Through `Loader.load_string/1` and `create_instances/1` -- the same path a reader's file takes -- so a snippet whose references do not resolve fails here rather than in the reader's terminal. This forces every documented snippet to be self-contained, which is the right property for a reference anyway.

**Every `expr` line evaluates.** Not parses -- evaluates. `Evaluator.parse/1` succeeds for anything Elixir can parse, because an unsupported form is refused when the resulting function is applied, not when it is built. A parse-only fence would have been green for every wrong example in the document. The fence builds one item carrying the fields, tags and metadata the examples read and applies each documented expression to it; an unsupported form raises `Unsupported expression` and goes red.

**Every public standard-library builder appears.** Enumerated from the modules, never transcribed, and written as the `STD.` name a `.pred` author actually types.

The document marks its blocks by what they are -- `pred` for complete definitions, `expr` for bare expressions -- which is the mechanism that lets one file carry two kinds of checked example.

### Mutation table

Numbering continues from WP-01's M1-M5.

| # | Mutation | Fence | Result |
| --- | ----------------------------------------------------- | ------------------------------- | ------ |
| M6 | a snippet references a loop that is not defined | snippets load and materialise | red |
| M7 | an unsupported form is added to an `expr` block | expressions evaluate | red |
| M8 | one builder's row is dropped from the reference | every builder appears | red |
| M9 | a new public builder lands in `StandardLib`, undocumented | every builder appears | red |
| M10 | a README route points at a file that is not there | every route resolves | red |

M9 is the one worth keeping. M8 only proves the fence reads the document; M9 proves it reads the *code*, and it failed naming `STD.Text.is_shouty/1` exactly -- which is what a transcribed table could never do.

M10 fenced a defect this thread was about to ship. The README's route to the language reference was written a work package before the file existed, and without the fence the only thing standing between that and a dead link in the published README was remembering.

### Critic

One round, clean. No findings at any severity over the four files this work touched, and none over all 108 in a full sweep.

An invocation note worth carrying: `--files "a.ex b.ex"` as one quoted string silently scans **one** file and reports `across 1 file(s)`. The paths must be separate arguments. The count in the output is the check -- read it, because a clean report over one file looks exactly like a clean report over four.

### Gate

484 passed (90 doctests, 394 tests), 790 mods/funs, zero credo findings.
