defmodule Riffle.Service do
  @moduledoc """
  THE way in. Runs a pipeline over rows read from a file.

  Every caller reaches Riffle through this module -- the CLI, the mix task, and
  whatever comes next. That is the point of it: a command-line command should
  parse arguments, call one function, and render the answer, and it can only
  stay that thin if the work it would otherwise do lives somewhere else.

  ## What it knows and what it does not

  It names the pattern layer, and through it the engine and the waist. It names
  **no CLI framework at all**, which is what keeps the library usable -- and its
  tests runnable -- by a caller that never loads one. The dependency is
  contained above this module, not threaded through it, and a fence in
  `test/riffle/boundary_fence_test.exs` holds it there.

  ## Two kinds of failure

  A path or a name that a correct caller can get wrong is a tagged error in the
  vocabulary below, and `message/1` turns each into a sentence. A shape outside
  the declared source vocabulary raises, because no correct program produces one.

  The pipeline is resolved **before** the run starts, so an unreadable source or
  an unknown pipeline name is a tagged error rather than a run that begins and
  then fails halfway. What is left inside the run is a raising predicate, and
  that propagates out unchanged -- see `Riffle.Sia`.

      iex> {:ok, result} = Riffle.Service.run(
      ...>   input: Path.join(:code.priv_dir(:riffle), "sia/sample.csv"),
      ...>   source: {:file, Path.join(:code.priv_dir(:riffle), "sia/sia.pred")},
      ...>   pipeline: :main
      ...> )
      iex> {result.pipeline, result.input_count, result.output_count}
      {:main, 10, 6}
      iex> result.stages
      [signal_loop: 9, inference_loop: 6, action_loop: 6]
  """

  alias Riffle.Ctx
  alias Riffle.Predicate.Pipeline
  alias Riffle.Service.Csv
  alias Riffle.Service.Result
  alias Riffle.Sia
  alias Riffle.Sia.Pipelines

  @type error ::
          Csv.error()
          | {:pipeline_unavailable, Pipelines.reason()}
          | {:source_ambiguous, [atom()]}
          | {:module_not_found, String.t()}

  @doc """
  Chooses a pipeline source from what a caller supplied.

  `:file` names a `.pred` file, `:module` names a `Riffle.Predicate.PipelineConfig`
  module, and supplying neither falls back to `:default_module` -- whatever
  `config :riffle, :default_pipeline` names, which is a clean tagged error when
  nothing is configured rather than a guess.

  The precedence lives here and not in a command because it is policy, not
  argument parsing: a second caller should inherit the same answer instead of
  reinventing one that disagrees. Supplying both is refused rather than silently
  resolved in favour of one -- a caller who names two sources has a belief about
  which runs, and half of those beliefs would be wrong.
  """
  @spec source(keyword()) :: {:ok, Pipelines.source()} | {:error, error()}
  def source(opts) do
    validated = Keyword.validate!(opts, [:file, :module])

    choose(
      presented(validated, :file),
      presented(validated, :module)
    )
  end

  defp presented(opts, key) do
    case Keyword.get(opts, key) do
      value when is_binary(value) and value != "" -> value
      _absent -> nil
    end
  end

  defp choose(file, module) when is_binary(file) and is_binary(module),
    do: {:error, {:source_ambiguous, [:file, :module]}}

  defp choose(file, nil) when is_binary(file), do: {:ok, {:file, file}}
  defp choose(nil, module) when is_binary(module), do: as_module(module)
  defp choose(nil, nil), do: {:ok, :default_module}

  # Concat rather than to_existing_atom: the module a caller names may be
  # perfectly real and simply not loaded yet, and refusing it for that reason
  # would be wrong. Loading is what decides, and a name nothing answers to is a
  # tagged error rather than a stray atom returned as if it were a pipeline.
  defp as_module(name) do
    module = Module.concat([name])

    case Code.ensure_loaded?(module) do
      true -> {:ok, {:module, module}}
      false -> {:error, {:module_not_found, name}}
    end
  end

  @doc """
  Runs a pipeline over the rows in a file.

  Options:

    * `:input` -- path to a CSV file whose first row is a header (required)
    * `:source` -- a `Riffle.Sia.Pipelines` source (required)
    * `:pipeline` -- which pipeline in that source; the source's default if absent
    * `:run_id` -- identifies the run; minted here if absent

  The run id is minted in this module and not in the waist, deliberately: the
  waist is a pure core and generating an identifier inside one is exactly the
  non-determinism it refuses. Impurity belongs at the edge, and this is the edge.
  """
  @spec run(keyword()) :: {:ok, Result.t()} | {:error, error()}
  def run(opts) do
    validated = Keyword.validate!(opts, [:input, :source, :pipeline, :run_id])
    input = Keyword.fetch!(validated, :input)
    source = Keyword.fetch!(validated, :source)

    with {:ok, pipeline} <- resolve(source, Keyword.get(validated, :pipeline)),
         {:ok, rows} <- Csv.read(input) do
      {:ok, execute(pipeline, rows, Keyword.get_lazy(validated, :run_id, &mint_run_id/0))}
    end
  end

  @doc """
  Lists the pipelines a source defines, by name, without running one.
  """
  @spec pipelines(Pipelines.source()) :: {:ok, [atom()]} | {:error, error()}
  def pipelines(source) do
    case Pipelines.names(source) do
      {:ok, names} -> {:ok, names}
      {:error, reason} -> {:error, {:pipeline_unavailable, reason}}
    end
  end

  @doc """
  Turns a tagged error into a sentence a person can act on.

  This lives here rather than in a command because it is business vocabulary,
  not presentation: what went wrong is the service's knowledge, and a second
  caller should not have to reinvent the wording to say the same thing.
  """
  @spec message(error()) :: String.t()
  def message({:input_not_found, path}), do: "input file not found: #{path}"

  def message({:input_unreadable, path, reason}),
    do: "cannot read input file #{path}: #{reason |> :file.format_error() |> List.to_string()}"

  def message({:input_empty, path}), do: "input file has no data rows: #{path}"
  def message({:input_malformed, path, detail}), do: "malformed input file #{path}: #{detail}"
  def message({:pipeline_unavailable, reason}), do: pipeline_message(reason)

  # Deliberately names neither caller's vocabulary. The CLI spells these
  # `--from` and `--from-module`; a library caller spells them `:file` and
  # `:module`. A message naming one would be wrong for the other, and a message
  # table in the command would duplicate this one.
  def message({:source_ambiguous, _keys}),
    do: "name one pipeline source, not two -- a file and a module were both given"

  def message({:module_not_found, name}),
    do: "no pipeline module named #{name} -- is it spelled correctly and compiled in?"

  defp pipeline_message({:pipeline_not_found, name, source}),
    do: "no pipeline named #{inspect(name)} in #{inspect(source)}"

  defp pipeline_message(:no_default_pipeline_module),
    do:
      "no pipeline source given and no default configured -- name a .pred file " <>
        "or a pipeline module, or set config :riffle, :default_pipeline"

  defp pipeline_message({:file_load_error, path, reason}),
    do: "cannot load pipeline file #{path}: #{inspect(reason)}"

  defp pipeline_message(reason), do: "pipeline source unavailable: #{inspect(reason)}"

  defp resolve(source, name) do
    case Pipelines.fetch(source, name) do
      {:ok, %Pipeline{} = pipeline} -> {:ok, pipeline}
      {:error, reason} -> {:error, {:pipeline_unavailable, reason}}
    end
  end

  defp execute(%Pipeline{} = pipeline, rows, run_id) do
    {ctx, emissions} = Sia.run(Ctx.new(run_id: run_id), pipeline, rows)

    %Result{
      pipeline: pipeline.name,
      input_count: length(rows),
      output_count: length(ctx.output),
      stages: stages(ctx),
      ctx: ctx,
      emissions: emissions
    }
  end

  # The summary is the pattern layer's own projection of the stage emissions it
  # produced, read back out. It is NOT recomputed here, and it is NOT derived
  # from the tags on surviving items: reconstructing stage identity by parsing
  # tag prefixes is what the archived layer did, and it hardcodes a three-stage
  # shape into the one place a user looks. A stage is a loop, and its name is
  # the loop's own -- so a four-loop pipeline summarises as four stages here
  # with no code change. Held by stage_agnostic_fence_test.
  #
  # Matched rather than defaulted: the pattern layer records this key on every
  # completed run, so its absence is a broken contract and should say so.
  defp stages(%Ctx{} = ctx) do
    {:ok, counts} = Ctx.fetch_metadata(ctx, :stage_counts)
    counts
  end

  defp mint_run_id, do: "riffle-#{System.unique_integer([:positive, :monotonic])}"
end
