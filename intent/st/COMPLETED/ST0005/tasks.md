# Tasks - ST0005: Documentation: moduledocs, ex_doc, and the .pred language reference

## Tasks

- [x] Survey all 61 modules before authoring the contract -- doctests, unrun examples, undocumented functions, unresolvable references
- [x] Author the acceptance contract (17 ACs across 3 WPs) against the measured survey rather than an estimate
- [x] WP-01: correct the root `Riffle` moduledoc, which taught the tag-prefix stage model ST0003 refuted and ST0004 fenced out
- [x] WP-01: rewrite the 20 perturbation and emission moduledocs -- meaning, payload fields, counterpart across the knot
- [x] WP-01: give the DSL-generated accessors their definitions' own descriptions
- [x] WP-01: make the five modules with unrun `iex>` lines carry real doctests, fixing the three that were wrong
- [x] WP-01: six doc-conformance fences, mutation-checked M1-M5
- [x] WP-02: wire `ex_doc` dev-only; group all 61 modules by the five layers; verify placement from the generated sidebar
- [x] WP-02: fix both warnings `mix docs` raised -- the dead LICENSE link and the hidden `Riffle.Application`
- [x] WP-02: make the README route, and add the `.pred` section it had never had
- [x] WP-03: measure the surface -- 3 definition forms, 3 body forms, 28 expression forms, 29 standard-library builders
- [x] WP-03: write `docs/pred-language.md` covering all of it
- [x] WP-03: three fences -- snippets load and materialise, expressions evaluate, the builder list is derived from the modules
- [x] WP-03: fence the README's routes; mutation-check M6-M10
- [x] WP-03: critic round, design.md and impl.md, close the thread

## Task Notes

The order hv set was the whole design: fix what the code says about itself before generating anything from it. It was vindicated immediately -- the moduledoc of the module named after the project taught a model the architecture had already refuted, and 44 lines of examples had never run.

Two fences reported this thread's own work while it was being written, and a third reported itself. That is the intended behaviour, and it is why the rule for counting examples tightened from "a line containing a prompt" to "a line beginning with one".

M9 is the mutation worth keeping: adding a public builder to `StandardLib` turned the coverage fence red naming `STD.Text.is_shouty/1` exactly. M10 caught a defect the thread was about to ship -- the README's route to the language reference was written a work package before the file existed.

## Dependencies

ST0001 through ST0004 all closed before this thread began; it documents the system all four built. WP-01 is a hard prerequisite of WP-02 -- documentation generated from moduledocs inherits whatever those moduledocs get wrong.
