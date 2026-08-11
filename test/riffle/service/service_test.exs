defmodule Riffle.ServiceTest do
  use ExUnit.Case, async: true

  doctest Riffle.Service

  alias Riffle.Service
  alias Riffle.ServiceFixtures

  # The service is THE way in. These tests hold two things: that one call runs a
  # pipeline over a file and reports what happened, and that every failure a
  # correct caller can provoke arrives as a tagged error naming the thing that
  # went wrong. The archived command met four of those five failures with a
  # warning and carried on -- a missing pipeline file logged and ignored, an
  # unknown pipeline name silently replaced by :main -- which is how a run
  # against the wrong definitions reports success.

  defp pred, do: Path.join(:code.priv_dir(:riffle), "sia/sia.pred")
  defp sample, do: Path.join(:code.priv_dir(:riffle), "sia/sample.csv")

  describe "run/1" do
    test "success: runs the shipped pipeline over the shipped sample" do
      {:ok, result} = Service.run(input: sample(), source: {:file, pred()}, pipeline: :main)

      assert result.pipeline == :main
      assert result.input_count == 10
      assert result.output_count == 6
      assert result.stages == [signal_loop: 9, inference_loop: 6, action_loop: 6]
    end

    test "success: a named pipeline other than the default runs the narrower cut" do
      {:ok, sense} =
        Service.run(input: sample(), source: {:file, pred()}, pipeline: :sense_pipeline)

      assert sense.pipeline == :sense_pipeline
      assert sense.stages == [signal_loop: 9]
      assert sense.output_count == 9
    end

    test "success: the result carries the context and emissions, so evidence survives the call" do
      {:ok, result} = Service.run(input: sample(), source: {:file, pred()}, pipeline: :main)

      assert result.ctx.status == :completed
      assert length(result.ctx.output) == result.output_count
      assert result.emissions != []

      # The counts the summary reports are the same values the run emitted --
      # not a tally kept beside them (bedrock 8).
      evidence =
        for %Riffle.Ctx.Emission.StageCompleted{stage: stage, output: output} <- result.emissions,
            do: {stage, length(output)}

      assert result.stages == evidence
    end

    test "success: a caller-supplied run id reaches the context" do
      {:ok, result} =
        Service.run(input: sample(), source: {:file, pred()}, run_id: "supplied-run-id")

      assert result.ctx.run_id == "supplied-run-id"
    end

    test "success: minted run ids differ between runs" do
      {:ok, first} = Service.run(input: sample(), source: {:file, pred()})
      {:ok, second} = Service.run(input: sample(), source: {:file, pred()})

      assert first.ctx.run_id != second.ctx.run_id
    end

    test "failure: an option the service does not declare is refused, not ignored" do
      assert_raise ArgumentError, fn ->
        Service.run(input: sample(), source: {:file, pred()}, pipelien: :main)
      end
    end

    test "failure: the input file is absent" do
      assert Service.run(input: "/nope/missing.csv", source: {:file, pred()}) ==
               {:error, {:input_not_found, "/nope/missing.csv"}}
    end

    test "failure: the input path is not a readable file" do
      assert {:error, {:input_unreadable, _path, :eisdir}} =
               Service.run(input: System.tmp_dir!(), source: {:file, pred()})
    end

    test "failure: the input carries no data rows" do
      input = ServiceFixtures.write_csv!("a,b\n")

      assert Service.run(input: input, source: {:file, pred()}) ==
               {:error, {:input_empty, input}}
    end

    test "failure: a row whose width differs from the header is refused, not padded" do
      input = ServiceFixtures.write_csv!("a,b\n1\n")

      assert Service.run(input: input, source: {:file, pred()}) ==
               {:error, {:input_malformed, input, "line 2 has 1 fields, header has 2"}}
    end

    test "failure: the pipeline file cannot be loaded" do
      assert Service.run(input: sample(), source: {:file, "/nope/x.pred"}) ==
               {:error, {:pipeline_unavailable, {:file_load_error, "/nope/x.pred", :enoent}}}
    end

    test "failure: the pipeline name is not present in the source" do
      assert {:error, {:pipeline_unavailable, {:pipeline_not_found, :nope, {:file, _path}}}} =
               Service.run(input: sample(), source: {:file, pred()}, pipeline: :nope)
    end

    test "failure: the pipeline is resolved before the input is read" do
      # Both are wrong. The pipeline error is the one reported, which is what
      # proves resolution happens first -- a run that read the file first would
      # report the input error and only discover the bad pipeline later.
      assert {:error, {:pipeline_unavailable, _reason}} =
               Service.run(input: "/nope/missing.csv", source: {:file, "/nope/x.pred"})
    end
  end

  describe "pipelines/1" do
    test "success: lists what a file source defines, sorted" do
      assert Service.pipelines({:file, pred()}) ==
               {:ok, [:infer_pipeline, :main, :sense_pipeline]}
    end

    test "success: lists what a module source defines" do
      assert Service.pipelines({:module, Riffle.Sia.DefaultPipeline}) ==
               {:ok, [:infer_pipeline, :main, :sense_pipeline]}
    end

    test "success: a struct source lists the one pipeline it is" do
      assert Service.pipelines(ServiceFixtures.four_loop_pipeline()) == {:ok, [:svc_four]}
    end

    test "failure: an unloadable source is a tagged error, not an empty list" do
      assert Service.pipelines({:file, "/nope/x.pred"}) ==
               {:error, {:pipeline_unavailable, {:file_load_error, "/nope/x.pred", :enoent}}}
    end
  end

  describe "message/1" do
    test "invariant: every tagged error renders a sentence naming what went wrong" do
      assert Service.message({:input_not_found, "/a.csv"}) == "input file not found: /a.csv"

      assert Service.message({:input_unreadable, "/a", :eisdir}) ==
               "cannot read input file /a: illegal operation on a directory"

      assert Service.message({:input_empty, "/a.csv"}) == "input file has no data rows: /a.csv"

      assert Service.message({:input_malformed, "/a.csv", "line 2"}) ==
               "malformed input file /a.csv: line 2"

      assert Service.message({:pipeline_unavailable, {:pipeline_not_found, :nope, :src}}) ==
               "no pipeline named :nope in :src"

      assert Service.message({:pipeline_unavailable, :no_default_pipeline_module}) ==
               "no pipeline source given and no default configured -- name a .pred file " <>
                 "or a pipeline module, or set config :riffle, :default_pipeline"

      assert Service.message({:source_ambiguous, [:file, :module]}) ==
               "name one pipeline source, not two -- a file and a module were both given"

      assert Service.message({:module_not_found, "No.Such"}) ==
               "no pipeline module named No.Such -- is it spelled correctly and compiled in?"

      assert Service.message({:pipeline_unavailable, {:file_load_error, "/x.pred", :enoent}}) ==
               "cannot load pipeline file /x.pred: :enoent"
    end
  end
end
