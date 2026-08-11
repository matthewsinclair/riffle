---
verblock: "11 Aug 2026:v0.2: cc - Design decisions as taken across WP-01..WP-03"
st_id: ST0005
title: "Documentation -- design"
---

# ST0005 Documentation -- Design

## Approach

Three work packages, in an order hv set: fix what the code already says about itself, then generate a reference from it, then write the one document the generated reference cannot produce.

WP-01 is a pass over all 61 moduledocs for richness and for agreement with the as-written code. WP-02 wires `ex_doc` and turns the README into a router. WP-03 writes `docs/pred-language.md`, the `.pred` language reference, and fences it.

The order is the whole design. Documentation generated from moduledocs inherits whatever those moduledocs get wrong, so correcting them second would mean publishing the errors first.

## Design Decisions

**DD-1: A documentation claim is checked mechanically wherever a machine can check it.** Not reviewed once and trusted after. A doc that drifts from the code goes red. This is what separates this thread from a writing exercise: the surface of the standard library, the resolvability of every `fun/arity` reference, the parseability of every example, and the existence of every route are all facts a test can hold.

**DD-2: The generated reference presents the architecture.** `groups_for_modules` is the five layers in the order the README gives them -- engine, waist, pattern layer, service, CLI -- so a reader meets the shape rather than an alphabetical list of 61 modules. Every module is placed explicitly, because an unplaced module falls into a trailing `Modules` bucket, which is exactly the alphabetical list the grouping exists to replace. The placement is checked by counting, not assumed.

**DD-3: `docs/` earns exactly one file.** Highlander applies to documentation. `docs/cli.md` is not written because `bin/riffle help` and `--help` already own the command surface, and a second copy would drift from the flags the code parses. `docs/architecture.md` is not written because `intent/docs/bedrock.md` owns the commitments and binds each to the fence that holds it. What is left that nothing owns is the `.pred` language, so that is the file that gets written. Ratified by hv.

**DD-4: The README is the router and the front page, one document.** `main: "readme"` makes the README the first page of the generated docs, so the routing table serves a reader arriving from GitHub and a reader arriving from the API reference without a second copy existing. The cost is that every relative link has to resolve in both places, which is why DD-10 exists.

**DD-5: A `.pred` snippet is checked by the thing that really reads `.pred` text.** Not by a parser stand-in and not by eye. Each snippet goes through `Riffle.Predicate.Dsl.Loader.load_string/1` and `create_instances/1`, so a snippet whose references do not resolve fails in the same way a reader's file would. That in turn forces every documented snippet to be self-contained, which is the right property for a reference anyway.

**DD-6: Expressions are checked by evaluating them, not by parsing them.** `Evaluator.parse/1` succeeds for any text Elixir can parse -- the refusal of an unsupported form happens when the resulting function is applied. A parse-only check would have passed for every wrong example in the document. So the fence builds one item carrying the fields, tags and metadata the examples read, and applies every documented expression to it.

**DD-7: The standard-library surface is derived from the modules, never transcribed.** The coverage fence enumerates the public functions of `Riffle.Predicate.StandardLib` and everything under it, and requires each to appear in the reference. Adding a builder makes the fence red until it is documented. A transcribed list would be correct exactly once.

**DD-8: Generated public functions carry real `@doc`, not `@doc false`.** The DSL macro generates one accessor per predicate, loop and pipeline. They are real API -- a caller reaches a definition by name through them -- so hiding them would be a lie of omission. Each now carries its own definition's description.

**DD-9: `Riffle.Application` is documented rather than hidden.** The conventional `@moduledoc false` on an OTP callback module is right when nothing points at it. Here `Riffle.Predicate.Cache.start_link/1` names it while explaining that a caller never starts the cache, and that is a fact a reader needs. Hiding the module would leave the prose pointing at nothing -- which is what `mix docs` reported.

**DD-10: A route is a claim, so it is fenced.** Every markdown link in the README with a repository-relative target must resolve. The fence exists because this thread nearly shipped the failure it catches: the language reference was linked from the README one work package before it was written.

## Architecture

Nothing in `lib/` changes shape. The thread adds one document (`docs/pred-language.md`), one build configuration (`docs/0` in `mix.exs`), and one fence file (`test/riffle/docs/pred_reference_test.exs`), and extends two that already existed.

The doc walks live in `Riffle.DocHelpers` (`test/support`) rather than beside the fences that use them, for the reason `mix.exs` already gives: support modules are ordinary Elixir, so they may use the `case` and `if` that IN-EX-TEST-005 forbids inside test bodies. Walking docs is branchy work. One home also means the two fence files cannot answer the same question differently.

The reference marks its code blocks by what they are -- `pred` for complete definitions, `expr` for bare expressions -- so each is checked by the right reader. That is the mechanism that lets one document carry two kinds of checked example.

## Alternatives Considered

**A `docs/` tree mirroring the layers.** Rejected under DD-3: every candidate file already had an owner, and a second copy of a command surface or an architecture is a copy that drifts.

**`@doc false` on the generated accessors.** Rejected under DD-8. It would have cleared the undocumented count without making anything clearer.

**Fencing snippets with `Parser.parse/1` alone.** Rejected under DD-5: it checks that a snippet is Elixir-shaped, not that it is a working set of definitions. An unresolvable reference would have passed.

**A transcribed standard-library table.** Rejected under DD-7. It is the shape of documentation that is right on the day it is written and wrong thereafter, and the mutation that adds a builder proves the difference.

**Markdown links throughout the README's routing table.** Rejected in part: a link to a repository file that is not an `ex_doc` extra does not resolve in the generated docs and `mix docs` says so. Only targets that are extras are linked; the rest are written as paths.
