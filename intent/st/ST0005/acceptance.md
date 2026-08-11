---
verblock: "11 Aug 2026:v0.1: cc - Contract authored against a measured survey of the existing docs"
st_id: ST0005
title: "Documentation: moduledocs, ex_doc, and the .pred language reference -- acceptance contract"
---

# ST0005 Documentation -- Acceptance

> Canonical acceptance contract for ST0005. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them. Real test code lives in the suite (paths cited below); this file is the contract plus the AC-to-AT coverage map plus live status. info.md / WP info.md reference this file and never restate ACs (one home).
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Change control: clarifying an AC or AT is verifier-and-builder; shrinking scope, or weakening an AT to make it pass, needs the owner.
>
> AT status vocabulary: to-write (red-first) | red | green | n/a (non-test: doc / eyeball / gate).
>
> Non-test ACs carry their state inline -- `-- evidence: <ref> -- satisfied: yes|no` on the AC line; test-backed ACs are satisfied by a green covering AT (computed, never written). Multi-AC coverage on an AT is comma-separated.
>
> What this contract is shaped by. A survey of all 61 modules run before it was written, and three findings from it. **The root `Riffle` moduledoc contradicts bedrock**: it teaches "three tag-driven stages" identified by `signal_*` / `inference_*` / `action_*` prefixes, which is exactly the model ST0003 DD-2 refuted (a stage is a loop; its identity is the loop's own name) and which ST0004 DD-7 fenced out of the CLI. It is the module named after the project and the first page ex_doc will render. **Four `fun/arity` references in docs do not resolve** -- cross-module references written unqualified, which read as prose and render as broken links. **The undocumented count is 15, not 124**: 109 of the apparent gaps are `@doc false` or generated and correctly hidden, and 13 of the remaining 15 are macro-generated accessors, so nothing hand-written is undocumented. The work is therefore accuracy and richness, not coverage.

## Acceptance Criteria

### ST-level

- AC-00.1 (non-test) `mix gate` green at close -- format, compile and test both under warnings-as-errors, `credo --strict` -- evidence: impl.md Gate section -- satisfied: no
- AC-00.2 (non-test) Every fence this thread adds is mutation-checked: break the thing it guards, watch it go red, restore -- evidence: impl.md mutation table -- satisfied: no
- AC-00.3 Documentation claims are checked mechanically wherever a machine can check them, rather than reviewed once and trusted thereafter. A doc that drifts from the code goes red

### WP-01 -- The moduledoc pass (status: WIP)

- AC-01.1 No moduledoc teaches a model the architecture refutes. In particular the root `Riffle` moduledoc no longer presents three fixed tag-driven stages: a pipeline has as many stages as it declares loops, and a stage's identity is the loop's own name
- AC-01.2 Every `Module.fun/arity` and `fun/arity` reference in every moduledoc and `@doc` resolves to something that exists, and this is enforced over the whole compiled application rather than fixed once
- AC-01.3 The typed vocabulary of the waist documents itself: each perturbation and each emission states what it means, what its payload carries, and how it relates to its counterpart across the knot. A reader can tell `StageProgress` from `StageCompleted` -- the distinction the D2 defect turned on -- from the docs alone
- AC-01.4 Generated public functions do not appear as undocumented API: a module built from the DSL presents its own surface, not one entry per predicate, loop and pipeline it defines
- AC-01.5 A module whose docs make a claim a doctest could check carries that doctest. Applied to the modules the survey found carrying substantial prose and zero executable examples
- AC-01.6 Every doctest in the tree passes, so every documented example is a checked example

### WP-02 -- ex_doc and the README (status: TODO)

- AC-02.1 (non-test) `mix docs` produces an API reference from the existing moduledocs, with the deps declared dev-only so the library's runtime dependencies are unchanged -- evidence: impl.md -- satisfied: no
- AC-02.2 (non-test) The generated reference is grouped so a reader meets the five layers in order rather than an alphabetical list of 61 modules -- evidence: mix.exs docs config -- satisfied: no
- AC-02.3 (non-test) The README routes: what Riffle is, the shape, how to run it, and where to go for the language reference, the API and the architecture -- evidence: README.md -- satisfied: no

### WP-03 -- The .pred language reference (status: TODO)

- AC-03.1 (non-test) `docs/pred-language.md` documents the whole `.pred` surface: the three definition forms, every expression form the evaluator accepts, and every standard-library predicate, each with an example -- evidence: docs/pred-language.md -- satisfied: no
- AC-03.2 Every `.pred` snippet in the reference parses. A wrong example goes red rather than misleading a reader
- AC-03.3 The reference covers the whole surface rather than a chosen subset: every public standard-library predicate is mentioned, checked against the modules themselves
- AC-03.4 (non-test) design.md and impl.md record the decisions, the as-built and the mutation table -- evidence: intent/st/ST0005/{design,impl}.md -- satisfied: no
- AC-03.5 (non-test) Rule-library conformance: `intent critic elixir` clean at every severity over every file this thread touches -- evidence: impl.md Critic rounds -- satisfied: no

## Acceptance Tests

### WP-01

- AT-01.1 test/riffle/docs/doc_conformance_test.exs (2: no doc describes stages as driven by tag prefixes, plus a control that the walk sees the phrasing) -- covers AC-01.1 -- status: green
- AT-01.2 test/riffle/docs/doc_conformance_test.exs (2: every reference resolves over the whole application, plus a both-directions control) -- covers AC-01.2, AC-00.3 -- status: green
- AT-01.3 test/riffle/docs/doc_conformance_test.exs (3: every catalog member describes each of its own fields, none left at one line, plus a control the catalogs are non-empty) -- covers AC-01.3 -- status: green
- AT-01.4 test/riffle/docs/doc_conformance_test.exs (2: a DSL module exposes no undocumented function, plus a control that accessors are really generated) -- covers AC-01.4 -- status: green
- AT-01.5 test/riffle/docs/doc_conformance_test.exs (2: every module with an example has a doctest running it, plus a control) and the 90 doctests themselves -- covers AC-01.5, AC-01.6 -- status: green
- Coverage: complete -- AC-01.1..6 each covered by an AT above.

### WP-02

- Coverage: none -- AC-02.1..3 are all non-test, with evidence inline.

### WP-03

- AT-03.1 test/riffle/docs/pred_reference_test.exs (every snippet parses) -- covers AC-03.2 -- status: to-write
- AT-03.2 test/riffle/docs/pred_reference_test.exs (every standard-library predicate is covered) -- covers AC-03.3 -- status: to-write
- Coverage: AC-03.2 and AC-03.3 covered above; AC-03.1, AC-03.4 and AC-03.5 are non-test, with evidence inline.
