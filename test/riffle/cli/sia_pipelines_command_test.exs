defmodule Riffle.Cli.Commands.SiaPipelinesCommandTest do
  use ExUnit.Case, async: true

  alias Arca.Cli.Ctx
  alias Riffle.Cli.Commands.SiaPipelinesCommand
  alias Riffle.ServiceFixtures

  defp pred, do: Path.join(:code.priv_dir(:riffle), "sia/sia.pred")

  defp invoke(options) do
    SiaPipelinesCommand.handle(%{args: %{}, options: Map.new(options), flags: %{}}, %{}, nil)
  end

  describe "handle/3" do
    test "success: lists what a file source defines" do
      ctx = invoke(from: pred())

      assert Ctx.outcome(ctx) == :ok
      assert {:list, ["infer_pipeline", "main", "sense_pipeline"]} in ctx.output
    end

    test "success: lists what a module source defines" do
      ctx = invoke(from_module: "Riffle.Sia.DefaultPipeline")

      assert Ctx.outcome(ctx) == :ok
      assert {:list, ["infer_pipeline", "main", "sense_pipeline"]} in ctx.output
    end

    test "success: a source with one pipeline lists one name" do
      ctx = invoke(from: ServiceFixtures.four_loop_pred!())

      assert Ctx.outcome(ctx) == :ok
      assert {:list, ["main"]} in ctx.output
    end

    test "failure: an unloadable source is an error, not an empty list" do
      ctx = invoke(from: "/nope/x.pred")

      assert Ctx.outcome(ctx) == :error
      assert [message] = ctx.errors
      assert message =~ "cannot load pipeline file /nope/x.pred"
      assert ctx.output == []
    end

    test "failure: naming two sources is refused" do
      ctx = invoke(from: pred(), from_module: "Riffle.Sia.DefaultPipeline")

      assert Ctx.outcome(ctx) == :error
      assert [message] = ctx.errors
      assert message =~ "name one pipeline source, not two"
    end

    test "failure: no source and no configured default is a sentence, not a crash" do
      ctx = invoke([])

      assert Ctx.outcome(ctx) == :error
      assert [message] = ctx.errors
      assert message =~ "no pipeline source given"
    end
  end
end
