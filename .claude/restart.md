# Claude Code -- restart focus

## State (2026-08-11)

All three steel threads closed. **The extraction is complete and nothing is queued.**

- ST0001 the Predicate engine (11/11) | ST0002 the Bowtie waist (17/17) | ST0003 the SIA pattern layer (22/22)
- `mix gate` green: 363 passed, zero credo findings, zero critic findings at any severity across 86 files

## On wake

1. `/in-session` -- required after every `/compact` or context reset. It chains `/in-whiteboard pickup cc`.
2. Read `intent/docs/bedrock.md` before any code. Eight commitments, each bound to the fence that holds it. A contradiction with it is a bug in the contradicting document.
3. Read `intent/wip.md` for the backlog and what each item is waiting on.

## The shape

The engine names nothing. The waist names nothing. The pattern layer names both and is named by neither. Held by `test/riffle/boundary_fence_test.exs` in all four directions.

`Riffle.Sia.run(ctx, source, input, opts)` stages a pipeline one loop at a time -- a stage *is* a loop. The impure step (predicate evaluation, cache behind a process) happens strictly between two `Knot.tick/2` calls, never inside one.

## Next unit of work

hv's call -- there is no queue. `intent/wip.md` lays out three candidates with reasoning; a second consumer is the one that would teach the most, because every mechanism here currently has exactly one.

## Standing rules

- `mix gate` green before every commit. Commit by explicit pathspec, never `-A`.
- Commits carry no AI attribution and end with `(C) hello@matthewsinclair.com`.
- Remotes are `local` and `upstream`. There is no `origin`.
- A fence that cannot fail is not a fence: mutation-check every new one.
- Archive (`~/Devel/_Archive/Multiplyer`) is read-only forensics; zero traces in `lib/` + `test/`.
