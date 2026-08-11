defmodule Riffle.Cli.Commands.SiaRunCommand do
  @moduledoc """
  `sia.run` -- run a pipeline over a file of rows.

  A thin coordinator: it turns argv into service arguments, makes one call, and
  renders what came back. It holds no business logic, and it is fenced from
  acquiring any -- `test/riffle/cli/thin_coordinator_fence_test.exs` refuses any
  reference from this layer to the engine, the waist or the pattern layer, so
  the shortcut of reaching past `Riffle.Service` cannot be taken quietly.

  Outcome and rendering belong to the framework. `handle/3` returns an
  `Arca.Cli.Ctx`, and `Arca.Cli` turns that into
  `{:ok, Ctx.outcome(ctx), Output.render(ctx)}` -- which is why there is no
  formatting, no exit-status plumbing and no error assembly here.
  """

  use Arca.Cli.Command.BaseCommand

  alias Arca.Cli.Ctx
  alias Riffle.Service

  config :"sia.run",
    name: "sia.run",
    about: "Run a pipeline over a file of rows",
    options: [
      input: [
        value_name: "FILE",
        long: "--input",
        short: "-i",
        help: "CSV file whose first row is a header",
        parser: :string,
        required: true
      ],
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
      ],
      pipeline: [
        value_name: "NAME",
        long: "--pipeline",
        short: "-p",
        help: "Which pipeline in that source (default: the source's own default)",
        parser: :string,
        required: false
      ],
      format: [
        value_name: "STYLE",
        long: "--format",
        help: "Output style: ansi, plain, json or dump",
        parser: :string,
        required: false
      ]
    ]

  @impl Arca.Cli.Command.CommandBehaviour
  def handle(args, settings, _optimus) do
    ctx = Ctx.for_command(:"sia.run", args, settings || %{})
    options = args.options

    with {:ok, ctx} <- styled(ctx, options[:format]),
         {:ok, source} <- Service.source(file: options[:from], module: options[:from_module]),
         {:ok, result} <- run(options, source) do
      report(ctx, result)
    else
      {:error, %Ctx{} = failed} -> failed
      {:error, reason} -> failure(ctx, Service.message(reason))
    end
  end

  # An unrecognised style is refused rather than quietly replaced by the
  # default. A caller who asked for `--format jsonn` wants JSON, and giving them
  # ANSI instead is a wrong answer delivered confidently.
  defp styled(ctx, nil), do: {:ok, ctx}

  defp styled(ctx, requested) do
    case Ctx.parse_style(requested) do
      {:ok, style} -> {:ok, Ctx.set_meta(ctx, :style, style)}
      :error -> {:error, failure(ctx, "unknown format #{inspect(requested)}")}
    end
  end

  defp run(options, source) do
    Service.run(
      input: options[:input],
      source: source,
      pipeline: pipeline_name(options[:pipeline])
    )
  end

  defp pipeline_name(nil), do: nil
  defp pipeline_name(name), do: String.to_atom(name)

  defp report(ctx, result) do
    ctx
    |> Ctx.add_output({:success, summary(result)})
    |> Ctx.add_output({:table, stage_rows(result), headers: ["stage", "kept"]})
    |> Ctx.complete(:ok)
  end

  defp summary(result) do
    "#{result.pipeline}: #{result.output_count} of #{result.input_count} rows kept"
  end

  # One row per stage the run actually reported, named by the loop's own name.
  # Nothing here knows how many stages there are or what they are called, which
  # is the whole point -- see Riffle.Service and DD-7.
  defp stage_rows(result) do
    Enum.map(result.stages, fn {stage, kept} -> [to_string(stage), to_string(kept)] end)
  end

  defp failure(ctx, message) do
    ctx
    |> Ctx.add_error(message)
    |> Ctx.complete(:error)
  end
end
