# riffle cli

Run Riffle's own command-line interface.

`bin/riffle cli [command] [args]` hands its arguments to the CLI and prints what
comes back. With no arguments it lists every command available.

## Commands

    sia.run          Run a pipeline over a file of rows
    sia.pipelines    List the pipelines a source defines

Plus the framework's own: `help`, `repl`, `history`, `redo`, `cfg.*`,
`settings.*`, `sys.*`, `dev.*`, `about`.

## Running a pipeline

    bin/riffle cli sia.run --input priv/sia/sample.csv --from priv/sia/sia.pred

    ✓ main: 6 of 10 rows kept
    ┌────────────────┬──────┐
    │ stage          │ kept │
    ├────────────────┼──────┤
    │ signal_loop    │ 9    │
    │ inference_loop │ 6    │
    │ action_loop    │ 6    │
    └────────────────┴──────┘

One row per loop the pipeline declares, named by that loop's own name. A
pipeline with four loops prints four rows -- the runner takes each loop as one
stage, and nothing here knows or assumes how many there are.

## Options for sia.run

    --input FILE       CSV file whose first row is a header (required)
    --from FILE        Pipeline definitions in a .pred file
    --from-module MOD  Pipeline definitions in a compiled module
    --pipeline NAME    Which pipeline in that source (default: the source's own)
    --format STYLE     ansi, plain, json or dump

Name `--from` or `--from-module`, not both. Naming neither falls back to
whatever `config :riffle, :default_pipeline` points at, which Riffle
deliberately leaves unset -- so the error tells you your three options rather
than quietly running an example pipeline you did not choose.

## Finding pipeline names

    bin/riffle cli sia.pipelines --from priv/sia/sia.pred

    * infer_pipeline
    * main
    * sense_pipeline

## Machine-readable output

    bin/riffle cli sia.run --input data.csv --from defs.pred --format json

## Interactive

    bin/riffle repl

Tab completion, command history and `redo`, all from the CLI framework.

## Related

- `bin/riffle help repl` -- the interactive shell
- `mix riffle.cli` -- the same CLI without the launcher
- `_build/escript/riffle` -- a standalone binary; build it with `mix escript.build`
