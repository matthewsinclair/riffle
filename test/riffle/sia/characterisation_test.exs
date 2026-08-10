defmodule Riffle.Sia.CharacterisationTest do
  # Reads and writes the :riffle application environment for the
  # :default_module source -- cannot run async.
  use ExUnit.Case, async: false

  alias Riffle.CacheHelpers
  alias Riffle.Ctx
  alias Riffle.Ctx.Emission
  alias Riffle.Sia
  alias Riffle.Sia.DefaultPipeline
  alias Riffle.SiaFixtures

  # The contract this thread inherited. Nine tests came across from the layer
  # being replaced. Five of them pinned `assert [] = results` -- deliberately,
  # as characterisation: the pipeline produced nothing, and pinning that made
  # the fact visible rather than tolerated, with a note that it would go red
  # when the pipeline worked again. It works again. Those five now assert the
  # concrete surviving rows and the concrete tags they carry.
  #
  # The other four asserted nothing at all. Each was shaped like
  # `assert %Ctx{} = ctx` -- true for any context, including one recording a
  # crash -- so a missing file, an unknown pipeline name and empty input were
  # all "passing" without a claim between them. They assert outcomes here.
  #
  # Results are read from `ctx.output`, which a completed run cannot leave
  # empty while claiming success: the evidence fence holds the output, the
  # emission and the final stage to the same value.

  @sense_survivors [
    {"100", [:signal_high_activity]},
    {"20", [:signal_churn_risk, :signal_premium_account]},
    {"120", [:signal_high_activity, :signal_premium_account]}
  ]

  @infer_survivors [
    {"100", [:inference_high_value_user, :inference_upsell_opportunity, :signal_high_activity]},
    {"120", [:inference_high_value_user, :signal_high_activity, :signal_premium_account]}
  ]

  @main_survivors [
    {"100",
     [
       :action_create_upsell,
       :action_send_promotion,
       :inference_high_value_user,
       :inference_upsell_opportunity,
       :signal_high_activity
     ]},
    {"120",
     [
       :action_send_promotion,
       :inference_high_value_user,
       :signal_high_activity,
       :signal_premium_account
     ]}
  ]

  setup do
    original = Application.fetch_env(:riffle, :default_pipeline)
    Application.put_env(:riffle, :default_pipeline, DefaultPipeline)

    # The evaluation cache is keyed on the predicate's name and the item, and
    # the module and the file share every predicate name. With it on, the first
    # run of a row warms the cache and every later run of that row -- whichever
    # source it came from -- answers from that one entry. The file's own
    # predicate bodies would then never execute, and the three "from a file"
    # tests below would be proving that the file parses, not that it works.
    #
    # Found by mutation: a deliberate drift between the file and the module
    # left these tests green.
    CacheHelpers.reset_cache(enabled: false)

    on_exit(fn ->
      CacheHelpers.reset_cache()

      case original do
        {:ok, value} -> Application.put_env(:riffle, :default_pipeline, value)
        :error -> Application.delete_env(:riffle, :default_pipeline)
      end
    end)

    :ok
  end

  defp run(source, opts \\ []) do
    Sia.run(
      Ctx.new(run_id: "characterisation"),
      source,
      SiaFixtures.characterisation_input(),
      opts
    )
  end

  defp survivors(%Ctx{output: output}) do
    for item <- output, do: {Map.fetch!(item.fields, "login_count"), Enum.sort(item.tags)}
  end

  defp file_source, do: {:file, DefaultPipeline.pred_path()}

  describe "the five that were pinned at no results" do
    test "success: the main pipeline from the default module tags two of four rows" do
      {ctx, _emissions} = run(:default_module)

      assert survivors(ctx) == @main_survivors
      assert ctx.metadata.stage_counts == [signal_loop: 3, inference_loop: 2, action_loop: 2]
    end

    test "success: the main pipeline from a file tags two of four rows" do
      {ctx, _emissions} = run(file_source())

      assert survivors(ctx) == @main_survivors
    end

    test "success: the sense pipeline from a file tags three of four rows" do
      {ctx, _emissions} = run(file_source(), pipeline: :sense_pipeline)

      assert survivors(ctx) == @sense_survivors
    end

    test "success: the sense pipeline from the default module tags three of four rows" do
      {ctx, _emissions} = run(:default_module, pipeline: :sense_pipeline)

      assert survivors(ctx) == @sense_survivors
    end

    test "success: the infer pipeline from a file narrows three rows to two" do
      {ctx, _emissions} = run(file_source(), pipeline: :infer_pipeline)

      assert survivors(ctx) == @infer_survivors
      assert ctx.metadata.stage_counts == [signal_loop: 3, inference_loop: 2]
    end
  end

  describe "the four that asserted nothing" do
    test "failure: a missing pipeline file fails the run and claims no results" do
      {ctx, emissions} = run({:file, "/nonexistent/pipeline.pred"})

      assert ctx.status == :failed
      assert ctx.errors == [{:file_load_error, "/nonexistent/pipeline.pred", :enoent}]
      assert ctx.output == nil

      assert [%Emission.ErrorRaised{error: {:file_load_error, _path, :enoent}}] =
               errors(emissions)

      assert produced(emissions) == []
    end

    test "failure: a pipeline name the default module does not define fails the run" do
      {ctx, emissions} = run(:default_module, pipeline: :no_such_pipeline)

      assert ctx.status == :failed
      assert ctx.errors == [{:pipeline_not_found, :no_such_pipeline, DefaultPipeline}]
      assert produced(emissions) == []
    end

    test "failure: a pipeline name the file does not define fails the run" do
      {ctx, emissions} = run(file_source(), pipeline: :no_such_pipeline)

      assert ctx.status == :failed
      assert ctx.errors == [{:pipeline_not_found, :no_such_pipeline, file_source()}]
      assert produced(emissions) == []
    end

    test "success: empty input completes with no results and a count of zero per stage" do
      {ctx, _emissions} =
        Sia.run(Ctx.new(run_id: "characterisation"), :default_module, [])

      assert ctx.status == :completed
      assert ctx.output == []
      assert ctx.errors == []
      assert ctx.metadata.stage_counts == [signal_loop: 0, inference_loop: 0, action_loop: 0]
    end
  end

  defp errors(emissions), do: for(%Emission.ErrorRaised{} = e <- emissions, do: e)
  defp produced(emissions), do: for(%Emission.OutputProduced{} = e <- emissions, do: e)
end
