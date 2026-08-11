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
      aliases: aliases(),
      escript: escript(),
      name: "Riffle",
      source_url: "https://github.com/matthewsinclair/riffle",
      docs: docs()
    ]
  end

  # The generated API reference. Its one job beyond rendering the moduledocs is
  # to present the architecture: `groups_for_modules` is the five layers in the
  # order the README gives them, so a reader meets the shape rather than 61
  # modules in alphabetical order. Every module is placed explicitly -- an
  # ungrouped leftover would land in a trailing "Modules" bucket, which is the
  # alphabetical list this grouping exists to avoid.
  defp docs do
    [
      main: "readme",
      # LICENSE rides along because the README links to it. An extra that is
      # not listed is a dead link in the generated docs, and ex_doc says so.
      extras: ["README.md", "docs/pred-language.md", "LICENSE"],
      # The README's mark is written as a repo-relative path, so the docs need
      # `design/` at the same relative position to render it.
      assets: %{"design" => "design"},
      logo: "design/riffle-mark.svg",
      favicon: "design/riffle-favicon.svg",
      source_ref: "main",
      nest_modules_by_prefix: [
        Riffle.Ctx.Perturbation,
        Riffle.Ctx.Emission,
        Riffle.Predicate.Dsl,
        Riffle.Predicate.StandardLib,
        Riffle.Cli.Commands
      ],
      groups_for_modules: [
        Overview: [Riffle],
        "The engine (Riffle.Predicate)": [~r/^Riffle\.Predicate($|\.)/, Riffle.Application],
        "The waist (Riffle.Ctx)": [~r/^Riffle\.Ctx($|\.)/],
        "The pattern layer (Riffle.Sia)": [~r/^Riffle\.Sia($|\.)/],
        "The service (Riffle.Service)": [~r/^Riffle\.Service($|\.)/],
        "The CLI (Riffle.Cli)": [~r/^Riffle\.Cli\./, Mix.Tasks.Riffle.Cli]
      ]
    ]
  end

  # A standalone binary running the same commands as `mix riffle.cli`, for the
  # caller who is not writing Elixir. `main_module` is the framework's own
  # entry point rather than anything of ours: the escript is a third doorway to
  # the same parser, not a third parser (ST0004 DD-4).
  defp escript do
    [
      main_module: Arca.Cli,
      path: "_build/escript/riffle",
      name: "riffle",
      # :riffle rather than nil. `app: nil` starts no OTP application, and the
      # framework's configuration server is an OTP process -- so the binary
      # built, ran, and died on the first command with a GenServer no-process
      # exit. Starting :riffle starts its dependencies with it.
      app: :riffle
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

      # Documentation generation. Dev-only and not loaded at runtime: the docs
      # are built from moduledocs already in the tree, so nothing a consumer of
      # this library depends on changes by having them.
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},

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
      # `AGENTS.md` tells an agent to run this, so it exists. There is no
      # database and nothing to migrate; fetching deps is the whole setup.
      setup: ["deps.get"],
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
