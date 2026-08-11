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

config :arca_cli,
  env: config_env(),
  name: "riffle",
  about: "Riffle",
  description: "Run data streams over composable predicate pipelines",
  version: "0.1.0",
  author: "hello@matthewsinclair.com",
  configurators: [
    Arca.Cli.Configurator.DftConfigurator,
    Riffle.Cli.Configurator
  ]

config :arca_config, config_domain: :riffle
