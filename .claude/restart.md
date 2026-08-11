# Claude Code -- restart focus

## State (2026-08-11)

All five steel threads closed. **The project is done to its charter and nothing is queued.**

- ST0001 the Predicate engine (11/11) | ST0002 the Bowtie waist (17/17) | ST0003 the SIA pattern layer (22/22) | ST0004 the service and the CLI (26/26) | ST0005 documentation (17/17)
- `mix gate` green: 484 passed (90 doctests, 394 tests), 790 mods/funs, zero credo findings, zero critic findings at any severity across 108 files
- `mix docs` clean at zero warnings; `mix escript.build` gives the standalone `riffle` binary

## On wake

1. `/in-session` -- required after every `/compact` or context reset. It chains `/in-whiteboard pickup cc`.
2. Read `intent/docs/bedrock.md` before any code. Eleven commitments, each bound to the fence that holds it. A contradiction with it is a bug in the contradicting document.
3. Read `intent/wip.md` for the backlog and what each item is waiting on, and `README.md` for where everything else lives.

## The shape

Five layers, each naming the one below it and named by none of them. The engine names nothing, the waist names nothing, the pattern layer names both, the service names the pattern layer and no delivery mechanism, the CLI names the service and nothing beneath it. Held by `test/riffle/boundary_fence_test.exs` and `test/riffle/cli/thin_coordinator_fence_test.exs`.

`Riffle.Service.run/1` is the way in. `Riffle.Sia.run(ctx, source, input, opts)` is one level below it and stages a pipeline one loop at a time -- a stage _is_ a loop. The impure step (predicate evaluation, cache behind a process) happens strictly between two `Knot.tick/2` calls, never inside one.

## Next unit of work

hv's call -- there is no queue. `intent/wip.md` lays out three candidates with reasoning. Publishing is blocked externally rather than undecided: `arca_cli` and `arca_config` are not on hex yet, and hv has moving them on the plan.

## Standing rules

- `mix gate` green before every commit. Commit by explicit pathspec, never `-A`.
- Commits carry no AI attribution and end with `(C) hello@matthewsinclair.com`.
- Remotes are `local` and `upstream`. There is no `origin`.
- A fence that cannot fail is not a fence: mutation-check every new one, with `cp` backups -- never `git checkout --`.
- A documentation claim a machine can check gets checked. That is bedrock 11, not a preference.
- Archive (`~/Devel/_Archive/Multiplyer`) is read-only forensics; zero traces in `lib/` + `test/`.
