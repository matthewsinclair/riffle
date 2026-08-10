defmodule Riffle.Predicate.Dsl.MacroTest do
  use ExUnit.Case, async: true

  # Define sample module using the macros
  defmodule TestPredicates do
    use Riffle.Predicate.Dsl.Macro

    defpredicate :active, "Active users" do
      fn item -> item.fields["status"] == "active" end
    end

    defpredicate :premium do
      fn item -> item.fields["tier"] == "premium" end
    end

    defloop :user_signals, "User signal detection" do
      predicate(:active)
      predicate(:premium)
    end

    defloop :subscription_signals do
      predicate(:premium)

      predicate :trial, "Trial users" do
        fn item -> item.fields["tier"] == "trial" end
      end
    end

    defpipeline :user_pipeline, "User processing pipeline" do
      loop(:user_signals)
      loop(:subscription_signals)
    end

    defpipeline :advanced_pipeline do
      loop(:user_signals)

      loop :extra_signals, "Extra user signals" do
        predicate(:active)

        predicate :new_user, "New user detection" do
          fn item ->
            created_at = item.fields["created_at"]
            now = DateTime.utc_now() |> DateTime.to_unix()

            created_unix =
              DateTime.from_iso8601(created_at)
              |> elem(1)
              |> DateTime.to_unix()

            # Less than 30 days
            now - created_unix < 86400 * 30
          end
        end
      end
    end
  end

  describe "predicate macros" do
    test "defines predicates with metadata" do
      predicates = TestPredicates.predicates()
      assert map_size(predicates) == 2
      assert Map.has_key?(predicates, :active)
      assert Map.has_key?(predicates, :premium)
    end

    test "creates predicate with description" do
      predicate = TestPredicates.get_predicate(:active)
      assert predicate.name == :active
      assert predicate.description == "Active users"
      assert match?({:fn, _, _}, predicate.body)
    end

    test "creates predicate without description" do
      predicate = TestPredicates.get_predicate(:premium)
      assert predicate.name == :premium
      assert predicate.description == ""
      assert match?({:fn, _, _}, predicate.body)
    end

    test "generates predicate struct" do
      predicate = TestPredicates.active()
      assert is_map(predicate)
      assert predicate.name == :active
      assert predicate.description == "Active users"
      assert is_function(predicate.function, 1)

      # Create a test item
      item = Riffle.Predicate.Item.create(%{"status" => "active", "tier" => "basic"})
      {matched, _item} = Riffle.Predicate.evaluate(predicate, item)
      assert matched == true

      # Create a non-matching item
      inactive_item =
        Riffle.Predicate.Item.create(%{"status" => "inactive", "tier" => "basic"})

      {matched, _item} = Riffle.Predicate.evaluate(predicate, inactive_item)
      assert matched == false
    end
  end

  describe "loop macros" do
    test "defines loops with metadata" do
      loops = TestPredicates.loops()
      assert map_size(loops) == 2
      assert Map.has_key?(loops, :user_signals)
      assert Map.has_key?(loops, :subscription_signals)
    end

    test "creates loop with description" do
      loop_def = TestPredicates.get_loop(:user_signals)
      assert loop_def.name == :user_signals
      assert loop_def.description == "User signal detection"
      assert length(loop_def.predicates) == 2

      [pred1, pred2] = loop_def.predicates
      assert pred1.name == :active
      assert pred1.inline == false
      assert pred2.name == :premium
      assert pred2.inline == false
    end

    test "creates loop with inline predicate" do
      loop_def = TestPredicates.get_loop(:subscription_signals)
      assert loop_def.name == :subscription_signals
      assert loop_def.description == ""
      assert length(loop_def.predicates) == 2

      [pred1, pred2] = loop_def.predicates
      assert pred1.name == :premium
      assert pred1.inline == false
      assert pred2.name == :trial
      assert pred2.description == "Trial users"
      assert pred2.inline == true
      assert match?({:fn, _, _}, pred2.body)
    end

    test "generates loop function" do
      loop = TestPredicates.user_signals()
      assert is_struct(loop, Riffle.Predicate.Loop)
      assert loop.name == :user_signals
      assert loop.description == "User signal detection"

      active_item = Riffle.Predicate.Item.create(%{"status" => "active", "tier" => "basic"})

      premium_item =
        Riffle.Predicate.Item.create(%{"status" => "active", "tier" => "premium"})

      inactive_item =
        Riffle.Predicate.Item.create(%{"status" => "inactive", "tier" => "basic"})

      filtered =
        loop
        |> Riffle.Predicate.Loop.filter([active_item, premium_item, inactive_item])
        |> Enum.to_list()

      assert [
               %Riffle.Predicate.Item{fields: %{"tier" => "basic"}, tags: [:active]},
               %Riffle.Predicate.Item{fields: %{"tier" => "premium"}, tags: [:premium, :active]}
             ] = filtered
    end
  end

  describe "pipeline macros" do
    test "defines pipelines with metadata" do
      pipelines = TestPredicates.pipelines()
      assert map_size(pipelines) == 2
      assert Map.has_key?(pipelines, :user_pipeline)
      assert Map.has_key?(pipelines, :advanced_pipeline)
    end

    test "creates pipeline with description" do
      pipeline_def = TestPredicates.get_pipeline(:user_pipeline)
      assert pipeline_def.name == :user_pipeline
      assert pipeline_def.description == "User processing pipeline"
      assert length(pipeline_def.loops) == 2

      [loop1, loop2] = pipeline_def.loops
      assert loop1.name == :user_signals
      assert loop1.inline == false
      assert loop2.name == :subscription_signals
      assert loop2.inline == false
    end

    test "creates pipeline with inline loop and predicate" do
      pipeline_def = TestPredicates.get_pipeline(:advanced_pipeline)
      assert pipeline_def.name == :advanced_pipeline
      assert pipeline_def.description == ""
      assert length(pipeline_def.loops) == 2

      [loop1, loop2] = pipeline_def.loops
      assert loop1.name == :user_signals
      assert loop1.inline == false

      assert loop2.name == :extra_signals
      assert loop2.description == "Extra user signals"
      assert loop2.inline == true
      assert length(loop2.predicates) == 2

      [pred1, pred2] = loop2.predicates
      assert pred1.name == :active
      assert pred1.inline == false

      assert pred2.name == :new_user
      assert pred2.description == "New user detection"
      assert pred2.inline == true
      assert match?({:fn, _, _}, pred2.body)
    end

    test "generates pipeline function" do
      pipeline = TestPredicates.user_pipeline()
      assert is_struct(pipeline, Riffle.Predicate.Pipeline)
      assert pipeline.name == :user_pipeline
      assert pipeline.description == "User processing pipeline"

      active_premium =
        Riffle.Predicate.Item.create(%{"status" => "active", "tier" => "premium"})

      active_basic = Riffle.Predicate.Item.create(%{"status" => "active", "tier" => "basic"})

      inactive_trial =
        Riffle.Predicate.Item.create(%{"status" => "inactive", "tier" => "trial"})

      inactive_basic =
        Riffle.Predicate.Item.create(%{"status" => "inactive", "tier" => "basic"})

      # Loops filter sequentially: user_signals (active OR premium) keeps
      # active_premium and active_basic; subscription_signals (premium OR
      # trial) then keeps only active_premium. inactive_trial dies in loop
      # one -- trial IS a subscription signal, but the item never gets there.
      filtered =
        pipeline
        |> Riffle.Predicate.Pipeline.process([
          active_premium,
          active_basic,
          inactive_trial,
          inactive_basic
        ])
        |> Enum.to_list()

      assert [%Riffle.Predicate.Item{fields: %{"tier" => "premium"}, tags: tags}] = filtered
      assert Enum.sort(tags) == [:active, :premium]
    end
  end

  describe "in-block junk fails the build" do
    test "failure: an unrecognised statement inside defloop raises at expansion" do
      assert_raise ArgumentError, ~r/unrecognised statement in defloop/, fn ->
        defmodule BadLoopDsl do
          use Riffle.Predicate.Dsl.Macro

          defpredicate :fine do
            fn _item -> true end
          end

          defloop :sloppy do
            predicate(:fine)
            predicat(:typo)
          end
        end
      end
    end

    test "failure: an unrecognised statement inside defpipeline raises at expansion" do
      assert_raise ArgumentError, ~r/unrecognised statement in defpipeline/, fn ->
        defmodule BadPipelineDsl do
          use Riffle.Predicate.Dsl.Macro

          defloop :fine_loop do
            predicate(:fine, "Inline", do: fn _item -> true end)
          end

          defpipeline :sloppy_pipeline do
            loop(:fine_loop)
            lop(:typo)
          end
        end
      end
    end
  end
end
