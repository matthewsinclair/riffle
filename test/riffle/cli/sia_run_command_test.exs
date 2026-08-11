defmodule Riffle.Cli.Commands.SiaRunCommandTest do
  use ExUnit.Case, async: true

  alias Arca.Cli.Ctx
  alias Riffle.Cli.Commands.SiaRunCommand
  alias Riffle.ServiceFixtures

  # These drive `handle/3` directly, because the thing under test is the
  # command's contract with the framework: what it returns. `Arca.Cli` turns
  # that into `{:ok, Ctx.outcome(ctx), Output.render(ctx)}`, so a command that
  # returns a well-formed Ctx has already delegated outcome and rendering --
  # which is the whole of AC-02.2 and the reason this file is short.

  defp pred, do: Path.join(:code.priv_dir(:riffle), "sia/sia.pred")
  defp sample, do: Path.join(:code.priv_dir(:riffle), "sia/sample.csv")

  defp invoke(options) do
    SiaRunCommand.handle(%{args: %{}, options: Map.new(options), flags: %{}}, %{}, nil)
  end

  describe "handle/3" do
    test "success: a good run completes :ok and reports the stages" do
      ctx = invoke(input: sample(), from: pred())

      assert %Ctx{} = ctx
      assert Ctx.outcome(ctx) == :ok
      assert ctx.errors == []
      assert {:success, "main: 6 of 10 rows kept"} in ctx.output

      assert {:table, [["signal_loop", "9"], ["inference_loop", "6"], ["action_loop", "6"]],
              headers: ["stage", "kept"]} in ctx.output
    end

    test "success: a named pipeline runs the narrower cut" do
      ctx = invoke(input: sample(), from: pred(), pipeline: "sense_pipeline")

      assert Ctx.outcome(ctx) == :ok
      assert {:success, "sense_pipeline: 9 of 10 rows kept"} in ctx.output
    end

    test "success: a module source runs without a file" do
      ctx = invoke(input: sample(), from_module: "Riffle.Sia.DefaultPipeline")

      assert Ctx.outcome(ctx) == :ok
      assert {:success, "main: 6 of 10 rows kept"} in ctx.output
    end

    test "fence: the table names whatever loops the pipeline has, not three fixed ones" do
      # The stage-agnosticism fence carried to the command line, where the
      # archived version of this broke. Four loops, names following no
      # convention, and the table must carry all four under their own names.
      # A command that assumed the shipped three-loop shape -- or rebuilt the
      # rows from tag prefixes, as the archived one did -- fails here.
      ctx =
        invoke(
          input: ServiceFixtures.numeric_csv!(1..6),
          from: ServiceFixtures.four_loop_pred!()
        )

      assert Ctx.outcome(ctx) == :ok
      assert {:success, "main: 3 of 6 rows kept"} in ctx.output

      assert {:table, [["alpha", "6"], ["bravo", "5"], ["charlie", "4"], ["delta", "3"]],
              headers: ["stage", "kept"]} in ctx.output
    end

    test "failure: no pipeline source given completes :error with a sentence" do
      ctx = invoke(input: sample())

      assert Ctx.outcome(ctx) == :error
      assert [message] = ctx.errors
      assert message =~ "no pipeline source given"
    end

    test "failure: naming two sources is refused rather than resolved to one" do
      ctx = invoke(input: sample(), from: pred(), from_module: "Riffle.Sia.DefaultPipeline")

      assert Ctx.outcome(ctx) == :error
      assert [message] = ctx.errors
      assert message =~ "name one pipeline source, not two"
    end

    test "failure: an unknown pipeline name is reported, never replaced by the default" do
      ctx = invoke(input: sample(), from: pred(), pipeline: "nope")

      assert Ctx.outcome(ctx) == :error
      assert [message] = ctx.errors
      assert message =~ "no pipeline named :nope"
    end

    test "failure: a missing input file is reported" do
      ctx = invoke(input: "/nope/missing.csv", from: pred())

      assert Ctx.outcome(ctx) == :error
      assert ctx.errors == ["input file not found: /nope/missing.csv"]
    end

    test "failure: a module nothing answers to is reported" do
      ctx = invoke(input: sample(), from_module: "No.Such.Pipeline")

      assert Ctx.outcome(ctx) == :error
      assert [message] = ctx.errors
      assert message =~ "no pipeline module named No.Such.Pipeline"
    end
  end

  describe "--format" do
    test "success: a recognised style is set on the context, not interpreted here" do
      ctx = invoke(input: sample(), from: pred(), format: "json")

      assert Ctx.outcome(ctx) == :ok
      assert ctx.meta[:style] == :json
    end

    test "success: every style the framework declares is accepted" do
      for style <- ~w(ansi plain json dump) do
        ctx = invoke(input: sample(), from: pred(), format: style)

        assert Ctx.outcome(ctx) == :ok
        assert ctx.meta[:style] == String.to_existing_atom(style)
      end
    end

    test "failure: an unknown style is refused, not silently defaulted" do
      ctx = invoke(input: sample(), from: pred(), format: "jsonn")

      assert Ctx.outcome(ctx) == :error
      assert ctx.errors == [~s(unknown format "jsonn")]
    end

    test "invariant: a refused style stops the run rather than running it unrendered" do
      # The style is parsed before the pipeline resolves, so a bad --format
      # never reaches the service. Proven by giving it an input that would
      # otherwise fail differently: the format error is the one reported.
      ctx = invoke(input: "/nope/missing.csv", from: pred(), format: "jsonn")

      assert ctx.errors == [~s(unknown format "jsonn")]
    end
  end

  describe "registration" do
    test "invariant: the command is declared through the framework's config macro" do
      config = SiaRunCommand.config()

      assert [{:"sia.run", opts}] = config
      assert opts[:name] == "sia.run"
      assert Keyword.has_key?(opts, :options)
    end

    test "invariant: the configurator lists every sia command" do
      commands = Riffle.Cli.Configurator.commands()

      assert Riffle.Cli.Commands.SiaCommand in commands
      assert Riffle.Cli.Commands.SiaRunCommand in commands
      assert Riffle.Cli.Commands.SiaPipelinesCommand in commands
    end
  end
end
