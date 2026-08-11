# cc archive -- 2026-08-11

Rolled out of the live board at localfold #6. Kept for the record; not reloaded on pickup.

## DOING (archived)

- (2026-08-11) **ST0004 CLOSED 26/26** -- the CLI. hv's ruling: service module holds the business logic, CLI and mix task are thin coordinators over it, arca_cli used properly with its own features. `Riffle.Service.run/1` is THE way in; `sia.run` / `sia.pipelines` sit over it; `bin/riffle cli`, `mix riffle.cli` and the escript are three doorways to one parser. Gate green -- 443 passed (69 doctests, 374 tests), 756 mods/funs, zero credo, zero critic findings across 105 files. Head `bdde201`.

## Resolved questions (archived)

- Whether Riffle ships a `config/` pointing `:default_pipeline` at the example. Answer: it ships `config/config.exs` for the CLI framework and deliberately does NOT set `:default_pipeline`. An omitted source is a tagged error naming the three ways to fix it, and `cli/config_test.exs` pins the absence so a future change has to be argued. (Open question from ST0003, settled in ST0004.)
- Whether `docs/` is worth having at all, or a rich README would do. Answer: both, plus ex_doc. Measured the surface first -- 28 expression forms and 25 standard-library predicates is reference material, not narrative, and a README that opens with an operator table has stopped being an introduction. Deliberately NOT written: `docs/cli.md` (already documented twice, by devbin help and by `--help`) and `docs/architecture.md` (that is `intent/docs/bedrock.md`). Highlander applies to documentation.
