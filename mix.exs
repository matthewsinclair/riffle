defmodule Riffle.MixProject do
  use Mix.Project

  def project do
    [
      app: :riffle,
      version: "0.1.0",
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def cli do
    [preferred_envs: [gate: :test]]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  # The quality gate: one definition, run locally and by CI as `mix gate`.
  # --force recompiles everything so a warm _build cannot hide warnings.
  defp aliases do
    [
      gate: [
        "format --check-formatted",
        "compile --warnings-as-errors --force",
        "test --warnings-as-errors"
      ]
    ]
  end
end
