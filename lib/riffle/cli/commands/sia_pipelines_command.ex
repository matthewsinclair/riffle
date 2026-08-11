defmodule Riffle.Cli.Commands.SiaPipelinesCommand do
  @moduledoc """
  `sia.pipelines` -- report what a source defines, without running anything.

  The question "what can I actually pass to `--pipeline`?" has an answer the
  source already knows, and a command line that cannot ask it leaves the user
  guessing at names. Same thinness as `sia.run`: parse, one call, render.
  """

  use Arca.Cli.Command.BaseCommand

  alias Arca.Cli.Ctx
  alias Riffle.Service

  config :"sia.pipelines",
    name: "sia.pipelines",
    about: "List the pipelines a source defines",
    options: [
      from: [
        value_name: "FILE",
        long: "--from",
        short: "-f",
        help: "Pipeline definitions in a .pred file",
        parser: :string,
        required: false
      ],
      from_module: [
        value_name: "MODULE",
        long: "--from-module",
        help: "Pipeline definitions in a compiled module",
        parser: :string,
        required: false
      ]
    ]

  @impl Arca.Cli.Command.CommandBehaviour
  def handle(args, settings, _optimus) do
    ctx = Ctx.for_command(:"sia.pipelines", args, settings || %{})
    options = args.options

    with {:ok, source} <- Service.source(file: options[:from], module: options[:from_module]),
         {:ok, names} <- Service.pipelines(source) do
      ctx
      |> Ctx.add_output({:list, Enum.map(names, &to_string/1)})
      |> Ctx.complete(:ok)
    else
      {:error, reason} ->
        ctx
        |> Ctx.add_error(Service.message(reason))
        |> Ctx.complete(:error)
    end
  end
end
