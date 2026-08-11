defmodule Riffle.Cli.ConfigTest do
  use ExUnit.Case, async: true

  # This file exists because of a real defect, found by hv rather than by the
  # suite: `bin/riffle cli` with no arguments raised
  #
  #   could not fetch application environment :url for application :arca_cli
  #
  # Every subcommand worked. `sia.run`, `sia.pipelines`, the escript, the
  # launcher -- all green, all verified. What was not verified was the bare
  # invocation, which prints the intro banner, which reads :url with
  # `fetch_env!`. :prompt_symbol was missing too, and would have taken the REPL
  # down the same way.
  #
  # Fixing the two keys would leave the class open, so the fence below reads the
  # framework's own source and requires that EVERY key it fetches with
  # `fetch_env!` is configured here. A new required key in a future arca_cli
  # arrives as a red test rather than as a stack trace in front of a user.

  @framework_sources "deps/arca_cli/lib/**/*.ex"

  test "fence: every application env key the framework requires of us is set" do
    required = required_keys()

    assert required != [],
           "found no fetch_env! calls in #{@framework_sources} -- the walk has gone dead"

    missing = Enum.filter(required, &(Application.fetch_env(:arca_cli, &1) == :error))

    assert missing == []
  end

  test "invariant: the walk sees a fetch_env! call" do
    # The positive control. Without it the fence above passes forever the moment
    # the AST shape stops matching, and the next missing key reaches a user.
    assert :url in required_keys()
    assert :prompt_symbol in required_keys()
  end

  test "invariant: our configurator is registered alongside the framework's default" do
    configurators = Application.fetch_env!(:arca_cli, :configurators)

    assert Riffle.Cli.Configurator in configurators
    assert Arca.Cli.Configurator.DftConfigurator in configurators
  end

  test "invariant: no default pipeline is configured" do
    # A deliberate absence, not an oversight (design.md, config/config.exs).
    # Setting it would make `sia.run` work with no --from and would also install
    # Riffle's own example as everyone's default pipeline. If this ever starts
    # failing, someone has made that choice and should have argued it.
    assert Application.fetch_env(:riffle, :default_pipeline) == :error
  end

  defp required_keys do
    @framework_sources
    |> Path.wildcard()
    |> Enum.flat_map(&keys_in/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp keys_in(path) do
    {_ast, keys} =
      path
      |> File.read!()
      |> Code.string_to_quoted!()
      |> Macro.prewalk([], &collect_fetch/2)

    keys
  end

  # `Application.fetch_env!(:arca_cli, :some_key)` -- only the literal-atom
  # form, because a computed key is not something this fence can check and
  # pretending otherwise would be worse than skipping it.
  defp collect_fetch(
         {{:., _, [{:__aliases__, _, [:Application]}, :fetch_env!]}, _, [:arca_cli, key]} = node,
         acc
       )
       when is_atom(key),
       do: {node, [key | acc]}

  defp collect_fetch(node, acc), do: {node, acc}
end
