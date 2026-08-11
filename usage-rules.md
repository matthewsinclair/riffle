# Riffle -- usage rules

Terse DO / NEVER contract. The reasoning lives in `intent/docs/bedrock.md`; this file is the short form. Where the two disagree, bedrock wins and this file is the bug.

## Using Riffle as a library

- DO enter through `Riffle.Service.run/1`. It reads the rows, resolves the pipeline, stages it, and returns a `Riffle.Service.Result` carrying the context, the emissions and the per-stage summary.
- DO use `Riffle.Sia.run/4` instead when you already have rows and want the pattern layer directly.
- DO name a pipeline source explicitly: a `Riffle.Predicate.Pipeline` struct, `{:module, Mod}`, `{:file, path}`, or `:default_module`. Riffle ships no default configuration, on purpose.
- DO read `result.stages` as a keyword list, one entry per loop the pipeline declares, under that loop's own name. A four-loop pipeline gives four entries.
- DO read `docs/pred-language.md` before writing a `.pred` file.
- NEVER assume three stages. A stage is a loop; the count is whatever the definitions declare.
- NEVER read a name off a tag prefix. `signal_` / `inference_` / `action_` are names in the shipped example, not a convention the runner enforces.
- NEVER treat a `Result` field as a summary of a summary. Every count in it is a projection of emitted evidence, and the evidence is in the same struct.

## Writing code in Riffle

### The shape

- DO respect the five layers. Each names the one below it and is named by none of them: engine (`Riffle.Predicate`) -> waist (`Riffle.Ctx`) -> pattern layer (`Riffle.Sia`) -> service (`Riffle.Service`) -> CLI (`Riffle.Cli`).
- DO put business logic in `Riffle.Service`. A CLI command parses, makes one call, and renders.
- NEVER name a waist module from the engine, or an engine module from the waist, at any depth of the call closure.
- NEVER name a service module from the engine, the waist or the pattern layer.
- NEVER name a CLI-framework module anywhere outside `lib/riffle/cli/`.
- NEVER reach past the service from a CLI module into the engine, the waist or the pattern layer.
- NEVER add a second argv parser. A doorway hands argv to the framework.

### The waist

- DO change a context only by applying a perturbation through `Riffle.Ctx.Knot.tick/2`.
- DO add a perturbation or emission type as the declared two-step ritual: the struct module, then the catalog entry.
- NEVER call anything impure from the knot -- no clock, no random, no process, no ETS, no file, no log. One logger call is a violation, not an exception.
- NEVER update a context outside the knot, in either spelling of update syntax.
- NEVER persist a perturbation or an emission in the context. They enter and they leave.
- NEVER record a boolean asserting that a payload exists next to that payload.

### Errors

- DO return a tagged error for a failure a correct program can meet: a missing file, a name nothing defines, an unset configuration.
- DO raise for a failure that means the program is wrong: a value outside a declared vocabulary, an argument contradicting another.
- DO name the exception type on every `rescue`.
- NEVER `rescue _ ->` or `rescue e ->`. A rescue-all makes a crash indistinguishable from a handled outcome.
- NEVER use `catch` or `after` to absorb a failure.
- NEVER return a quiet empty result where something went wrong.

### Tests and fences

- DO write a conformance fence -- assert the invariant over an exhaustively enumerated source of truth -- rather than an example test, wherever the claim is a whole-class one.
- DO mutation-check every new fence: break the thing it guards, watch it go red, restore. Use `cp` backups.
- DO give a fence a positive control when its discriminator would otherwise never fire.
- DO derive a fence's expectations from the code. A transcribed list is correct exactly once.
- NEVER trust a fence that has never been red. A fence that cannot fail is not a fence.
- NEVER compare two definition sources without disabling the evaluation cache. It keys on the predicate's _name_, so two sources sharing a name share an entry.

### Documentation

- DO add the `doctest` declaration in the same edit as the `iex>` example. An example nothing runs is a claim, not an example.
- DO write `fun/arity` references so they resolve; unqualified means "in this module".
- DO document a generated public function. Hiding real API is a lie of omission.
- NEVER let a documented claim a machine could check go unchecked.

## Working on the repository

- DO run `mix gate` green before every commit: format, compile and test under warnings-as-errors, plus `credo --strict`.
- DO run `intent critic elixir --files a.ex b.ex` with the paths as separate arguments, and read the `across N file(s)` count -- one quoted string scans one file.
- DO commit by explicit pathspec.
- NEVER `git commit -A`.
- NEVER put AI attribution in a commit message. Commits end with `(C) hello@matthewsinclair.com`.
- NEVER reference the source project in `lib/` or `test/`. `intent/` and the README are the declared exception, and `test/riffle/extrication_gate_test.exs` enforces the rest.
- NEVER hand-wrap markdown.
