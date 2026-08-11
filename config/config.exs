import Config

# Configuration for Riffle's OWN build only. Mix does not read a dependency's
# config, so nothing here reaches a project that depends on :riffle -- which is
# exactly the property that lets the CLI be configured without wiring anything
# into a library consumer's application.
#
# Note what is deliberately absent: `config :riffle, :default_pipeline`. Setting
# it would make `sia.run` work with no `--from`, and would also install Riffle's
# own example as everyone's default -- the framework smell this project has
# avoided throughout. Unset, an omitted source is a clean tagged error naming
# the three ways to fix it. The shipped definitions are still one flag away:
#
#     riffle sia.run --input priv/sia/sample.csv --from priv/sia/sia.pred

# Every key below is required, not decorative. The framework reads :url and
# :prompt_symbol with fetch_env!, so an unset one is not a missing nicety --
# it raises. :url is read by the intro banner, which is what a bare `riffle`
# with no arguments prints, and :prompt_symbol by the REPL. Both were omitted
# in the first draft of this file, and both subcommand paths worked perfectly
# while the two entry points a new user reaches first did not.
config :arca_cli,
  env: config_env(),
  name: "riffle",
  about: "Riffle",
  description: "Run data streams over composable predicate pipelines",
  version: "0.1.0",
  author: "hello@matthewsinclair.com",
  url: "https://github.com/matthewsinclair/riffle",
  # The REPL renders "<symbol> <history count> > ", so a ">" here reads as
  # "> 0 >". A riffle is water running over stone.
  prompt_symbol: "~",
  configurators: [
    Arca.Cli.Configurator.DftConfigurator,
    Riffle.Cli.Configurator
  ]

config :arca_config, config_domain: :riffle
