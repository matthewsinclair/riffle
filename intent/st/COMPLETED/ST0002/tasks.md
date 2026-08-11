# Tasks - ST0002: ctx-next, the Bowtie waist

## Tasks

- [x] Author the acceptance contract (17 ACs across 3 WPs) before any code
- [x] Record the design and the alternatives rejected, including multi-clause dispatch over a subscriber routing table
- [x] Register every new module in MODULES.md before creating its file
- [x] WP-01: `Riffle.Ctx` as a typed composite root -- every slot typed, exactly one declared free-form overlay, no slot accumulating perturbations or emissions
- [x] WP-01: both catalogs as closed registries, tag maps built at compile time, unknown tags loud-failing
- [x] WP-01: the catalog bijection fence -- struct modules on disk against the declared implementations, tags unique within each catalog
- [x] WP-01: the boundary fences -- the waist names no engine module and the engine names no waist module
- [x] WP-01: author the capability map -- each of the 24 measured Ctx functions mapped to a perturbation, an emission or a state read, or dropped with a reason
- [x] WP-02: `Riffle.Ctx.Knot.tick/2` -- pure, total, multi-clause, the single transition point
- [x] WP-02: the purity fence over the compiled call closure; the delivery-floor fence over every catalogued perturbation
- [x] WP-02: determinism and replay -- the same sequence reproduces an identical trajectory
- [x] WP-03: the measured-surface fence -- coverage by enumeration, both directions, with declared drops carrying their reasons
- [x] WP-03: write `intent/docs/bedrock.md` -- the commitments, the negations, and the rule that a contradiction with it is a bug in the contradicting document
- [x] WP-03: strike the inherited "reference implementation" claim (hv ruling) so it stops steering later sessions
- [x] WP-03: mutation checks, critic round, close the thread

## Task Notes

Two things this thread is remembered for.

The dead fence. One of the fences matched the Erlang remote-type form with the wrong arity, so it silently recognised nothing and passed for the wrong reason. Mutation testing found it. Two fences carry positive controls because of it, and "a fence that cannot fail is not a fence" became a standing rule from here.

The claim that outlived its correction. hv ruled that Riffle is an example of the Bowtie pattern rather than its reference implementation, and AC-03.6 struck the sentence from two documents. It survived in the README -- the most public document in the repo -- for a day. "A ruling is not applied until it is applied everywhere" comes from this thread, and the globalfold at the end of ST0005 found the same failure mode a third time, in `bedrock.md` itself.

The compiler did real work here: it proved the delivery floor's empty-result clause unreachable and the closed registry non-empty.

## Dependencies

ST0001 (the ported engine) closed before this thread began. The waist names nothing the engine defines, and the engine names nothing the waist defines -- so the two are independent by construction, and ST0003 is the thread that composes them.
