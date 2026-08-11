---
verblock: "11 Aug 2026:v0.2: cc - WP-02 and WP-03 closed; every AC satisfied or covered"
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

- AC-00.1 (non-test) `mix gate` green at close -- format, compile and test both under warnings-as-errors, `credo --strict` -- evidence: impl.md WP-03 Gate section -- satisfied: yes
- AC-00.2 (non-test) Every fence this thread adds is mutation-checked: break the thing it guards, watch it go red, restore -- evidence: impl.md mutation tables M1-M10 -- satisfied: yes
- AC-00.3 Documentation claims are checked mechanically wherever a machine can check them, rather than reviewed once and trusted thereafter. A doc that drifts from the code goes red

### WP-01 -- The moduledoc pass (status: DONE)

- AC-01.1 No moduledoc teaches a model the architecture refutes. In particular the root `Riffle` moduledoc no longer presents three fixed tag-driven stages: a pipeline has as many stages as it declares loops, and a stage's identity is the loop's own name
- AC-01.2 Every `Module.fun/arity` and `fun/arity` reference in every moduledoc and `@doc` resolves to something that exists, and this is enforced over the whole compiled application rather than fixed once
- AC-01.3 The typed vocabulary of the waist documents itself: each perturbation and each emission states what it means, what its payload carries, and how it relates to its counterpart across the knot. A reader can tell `StageProgress` from `StageCompleted` -- the distinction the D2 defect turned on -- from the docs alone
- AC-01.4 Generated public functions do not appear as undocumented API: a module built from the DSL presents its own surface, not one entry per predicate, loop and pipeline it defines
- AC-01.5 A module whose docs make a claim a doctest could check carries that doctest. Applied to the modules the survey found carrying substantial prose and zero executable examples
- AC-01.6 Every doctest in the tree passes, so every documented example is a checked example

### WP-02 -- ex_doc and the README (status: DONE)

- AC-02.1 (non-test) `mix docs` produces an API reference from the existing moduledocs, with the deps declared dev-only so the library's runtime dependencies are unchanged -- evidence: impl.md WP-02 As built -- satisfied: yes
- AC-02.2 (non-test) The generated reference is grouped so a reader meets the five layers in order rather than an alphabetical list of 61 modules -- evidence: mix.exs `docs/0`, group counts in impl.md WP-02 -- satisfied: yes
- AC-02.3 (non-test) The README routes: what Riffle is, the shape, how to run it, and where to go for the language reference, the API and the architecture -- evidence: README.md Where to go next; also covered by AT-02.1 -- satisfied: yes

### WP-03 -- The .pred language reference (status: DONE)

- AC-03.1 (non-test) `docs/pred-language.md` documents the whole `.pred` surface: the three definition forms, every expression form the evaluator accepts, and every standard-library predicate, each with an example -- evidence: docs/pred-language.md; surface counts in impl.md WP-03 -- satisfied: yes
- AC-03.2 Every `.pred` snippet in the reference parses. A wrong example goes red rather than misleading a reader
- AC-03.3 The reference covers the whole surface rather than a chosen subset: every public standard-library predicate is mentioned, checked against the modules themselves
- AC-03.4 (non-test) design.md and impl.md record the decisions, the as-built and the mutation table -- evidence: intent/st/ST0005/{design,impl}.md -- satisfied: yes
- AC-03.5 (non-test) Rule-library conformance: `intent critic elixir` clean at every severity over every file this thread touches -- evidence: impl.md WP-03 Critic -- satisfied: yes

## Acceptance Tests

### WP-01

- AT-01.1 test/riffle/docs/doc_conformance_test.exs (2: no doc describes stages as driven by tag prefixes, plus a control that the walk sees the phrasing) -- covers AC-01.1 -- status: green
- AT-01.2 test/riffle/docs/doc_conformance_test.exs (2: every reference resolves over the whole application, plus a both-directions control) -- covers AC-01.2, AC-00.3 -- status: green
- AT-01.3 test/riffle/docs/doc_conformance_test.exs (3: every catalog member describes each of its own fields, none left at one line, plus a control the catalogs are non-empty) -- covers AC-01.3 -- status: green
- AT-01.4 test/riffle/docs/doc_conformance_test.exs (2: a DSL module exposes no undocumented function, plus a control that accessors are really generated) -- covers AC-01.4 -- status: green
- AT-01.5 test/riffle/docs/doc_conformance_test.exs (2: every module with an example has a doctest running it, plus a control) and the 90 doctests themselves -- covers AC-01.5, AC-01.6 -- status: green
- Coverage: complete -- AC-01.1..6 each covered by an AT above.

### WP-02

- AT-02.1 test/riffle/docs/doc_conformance_test.exs (2: every link in the README resolves to something in the repository, plus a control that the walk sees the routes it checks) -- covers AC-02.3, AC-00.3 -- status: green
- Coverage: AC-02.1 and AC-02.2 are non-test, with evidence inline. AC-02.3 was authored non-test and was strengthened to a fence during the work: a route to a file that does not exist is a claim a machine can check, and this thread nearly shipped one.

### WP-03

- AT-03.1 test/riffle/docs/pred_reference_test.exs (3: every `pred` snippet loads AND materialises through the loader, plus controls that a non-definition and an unresolvable reference are both reported) -- covers AC-03.2 -- status: green
- AT-03.2 test/riffle/docs/pred_reference_test.exs (2: every public builder the modules declare appears in the reference, plus a control that the surface is derived rather than transcribed) -- covers AC-03.3 -- status: green
- AT-03.3 test/riffle/docs/pred_reference_test.exs (2: every documented expression is a form the evaluator accepts, checked by evaluating it, plus a control that a form outside the language is reported) -- covers AC-03.1, AC-00.3 -- status: green
- Coverage: AC-03.2 and AC-03.3 covered above, and AC-03.1's expression clause is covered by AT-03.3; AC-03.1, AC-03.4 and AC-03.5 carry their evidence inline.
