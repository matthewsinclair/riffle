defmodule Riffle.MixProject do
  use Mix.Project

  def project do
    [
      app: :riffle,
      version: "0.1.0",
      elixir: "~> 1.20",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # test/support holds shared test fixtures and helpers (test-highlander)
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  def cli do
    [preferred_envs: [gate: :test]]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Riffle.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # The CLI framework. Pinned to a tag, not tracked on `main`: this project's
      # whole discipline is a gate that stays green, and a dependency that can
      # change underneath a green gate defeats it. Moves to hex later, at which
      # point this line becomes an ordinary version requirement.
      {:arca_cli, github: "matthewsinclair/arca-cli", tag: "v0.5.0"},

      # CSV reading for the service module's file input. The engine, the waist
      # and the pattern layer take rows, not files -- reading them is the
      # service's job, and parsing CSV correctly is not this project's problem
      # to solve twice.
      {:nimble_csv, "~> 1.3"},

      # Static analysis. The same line every other elixir project in both fleets
      # carries (arca_cli, arca_config, Baize, Prolix), and it is what
      # `bin/riffle test credo` runs. Without it that gate dies with "the task
      # credo could not be found", which reads as a broken launcher rather than
      # as a dependency this project never had.
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  # The quality gate: one definition, run locally and by CI as `mix gate`.
  # --force recompiles everything so a warm _build cannot hide warnings.
  defp aliases do
    [
      gate: [
        "format --check-formatted",
        "compile --warnings-as-errors --force",
        "test --warnings-as-errors",
        # Credo joins the gate now that the tree is at zero findings. A clean
        # baseline no CI job enforces is a baseline that rots between sessions;
        # what the check MEANS still lives in .credo.exs, not here.
        "credo --strict"
      ]
    ]
  end
end
