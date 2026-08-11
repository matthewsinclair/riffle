defmodule Riffle.Cli.Configurator do
  @moduledoc """
  THE command list.

  One place names the commands the CLI offers. Registered with the framework in
  `config/config.exs` alongside its default configurator, which is what supplies
  `help`, `repl`, `history`, `cfg.*` and the rest -- none of which this project
  writes or maintains.
  """

  use Arca.Cli.Configurator.BaseConfigurator

  config :riffle_cli,
    commands: [
      Riffle.Cli.Commands.SiaCommand,
      Riffle.Cli.Commands.SiaRunCommand,
      Riffle.Cli.Commands.SiaPipelinesCommand
    ],
    author: "hello@matthewsinclair.com",
    about: "Riffle",
    description: "Run data streams over composable predicate pipelines",
    version: "0.1.0"
end
