defmodule Riffle.Cli.Commands.SiaCommand do
  @moduledoc """
  The `sia` namespace parent.

  Carries no behaviour of its own -- it exists so `riffle sia` prints what lives
  under it rather than an unknown-command error, which is the framework's
  dot-notation grouping doing its job.
  """

  use Arca.Cli.Command.BaseCommand

  @cli_help_text """
  Sense-infer-act commands.

  A pipeline is a sequence of loops, and the runner takes each loop as one
  stage -- so the three the shipped definitions declare are what those
  definitions say, not a shape the runner imposes.

    sia.run          Run a pipeline over a file of rows
    sia.pipelines    List the pipelines a source defines

  Examples:
    riffle sia.pipelines --from priv/sia/sia.pred
    riffle sia.run --input priv/sia/sample.csv --from priv/sia/sia.pred
    riffle sia.run --input data.csv --from defs.pred --pipeline sense_pipeline
    riffle sia.run --input data.csv --from defs.pred --format json
  """

  config :sia,
    name: "sia",
    about: "Sense-infer-act commands",
    help: @cli_help_text,
    show_help_on_empty: true
end
