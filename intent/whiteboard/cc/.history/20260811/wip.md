# cc archive -- 2026-08-11

Rolled out of the live board at localfold #6. Kept for the record; not reloaded on pickup.

## DOING (archived)

- (2026-08-11) **ST0004 CLOSED 26/26** -- the CLI. hv's ruling: service module holds the business logic, CLI and mix task are thin coordinators over it, arca_cli used properly with its own features. `Riffle.Service.run/1` is THE way in; `sia.run` / `sia.pipelines` sit over it; `bin/riffle cli`, `mix riffle.cli` and the escript are three doorways to one parser. Gate green -- 443 passed (69 doctests, 374 tests), 756 mods/funs, zero credo, zero critic findings across 105 files. Head `bdde201`.

## Resolved questions (archived)

- Whether Riffle ships a `config/` pointing `:default_pipeline` at the example. Answer: it ships `config/config.exs` for the CLI framework and deliberately does NOT set `:default_pipeline`. An omitted source is a tagged error naming the three ways to fix it, and `cli/config_test.exs` pins the absence so a future change has to be argued. (Open question from ST0003, settled in ST0004.)
- Whether `docs/` is worth having at all, or a rich README would do. Answer: both, plus ex_doc. Measured the surface first -- 28 expression forms and 25 standard-library predicates is reference material, not narrative, and a README that opens with an operator table has stopped being an introduction. Deliberately NOT written: `docs/cli.md` (already documented twice, by devbin help and by `--help`) and `docs/architecture.md` (that is `intent/docs/bedrock.md`). Highlander applies to documentation.

---

Rolled out of the live board at the globalfold, end of day 2026-08-11.

## DOING (archived)

- (2026-08-11) **ST0005 CLOSED 17/17 -- and with it, all five threads.** WP-02 wired `ex_doc` dev-only with all 61 modules placed explicitly across six groups (Overview plus the five layers, in the README's order), and fixed the two real warnings it surfaced -- a dead `LICENSE` link and a `@moduledoc false` module that the Cache's own docs pointed at. WP-03 wrote `docs/pred-language.md` covering 3 definition forms, 3 body forms, 28 expression forms and 29 standard-library builders, with three fences: snippets load AND materialise through the real loader, expressions are evaluated rather than parsed, and the builder list is derived from the modules. Five mutations, all red. Gate green -- 484 passed (90 doctests, 394 tests), 790 mods/funs, zero credo, zero critic findings across 108 files; `mix docs` clean at zero warnings. Head `1efaf94`.

## Globalfold findings (archived)

- **`intent/docs/bedrock.md` was two layers behind the system it governs.** It carried three parts and eight commitments; ST0004 had added the service and the CLI with five fences between them, and ST0005 had added the documentation discipline with six more. The README had been claiming for a day that bedrock held the commitments for all five layers. Bedrock now carries eleven commitments, eleven negations, and nineteen fence rows. This is the third instance of the same failure mode in five threads -- a ruling applied in most places, not all -- and the first where the *authoritative* document was the one left behind.
- **`usage-rules.md` did not exist**, and `CLAUDE.md` referenced it three times and `AGENTS.md` once as the project's terse DO / NEVER contract. Written.
- **`mix setup` was a false claim** the moment `intent agents sync` learned the project was Elixir: the generated `AGENTS.md` tells an agent to run it and there was no such alias. Added `setup: ["deps.get"]` rather than editing a generated file.
- Tree indexes had never been generated for `lib/mix`, `lib/riffle/cli`, `lib/riffle/service`, `test/riffle/cli`, `test/riffle/docs`, `test/riffle/service`, `bin` or `docs`. Generated.
