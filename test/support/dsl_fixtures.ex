defmodule Riffle.DslFixtures do
  @moduledoc """
  The canonical DSL fixture corpus (test-highlander): the consumer-side macro
  module and the `.pred` sources shared across the registry and loader suites
  live here and nowhere else. `Riffle.Predicate.Dsl.MacroTest` keeps its own
  fixture module by design -- there the DSL definitions ARE the subject under
  test, and intentionally varied setup is exempt.
  """

  defmodule UserPredicates do
    @moduledoc false
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

    defpipeline :user_pipeline, "User processing pipeline" do
      loop(:user_signals)
    end
  end

  @doc """
  `.pred` source: the basic user corpus (active/premium predicates, the
  user_signals loop, the user_pipeline).
  """
  @spec basic_source() :: String.t()
  def basic_source do
    """
    predicate(:active, "Active users") do
      fn item -> item.fields["status"] == "active" end
    end

    predicate(:premium, "Premium users") do
      fn item -> item.fields["tier"] == "premium" end
    end

    loop(:user_signals, "User signal detection") do
      predicate(:active)
      predicate(:premium)
    end

    pipeline(:user_pipeline, "User processing pipeline") do
      loop(:user_signals)
    end
    """
  end

  @doc "`.pred` source: the trial corpus (predicate, loop, pipeline)."
  @spec trial_source() :: String.t()
  def trial_source do
    """
    predicate(:trial, "Trial users") do
      fn item -> item.fields["tier"] == "trial" end
    end

    loop(:trial_signals, "Trial signals") do
      predicate(:trial)
    end

    pipeline(:trial_pipeline, "Trial pipeline") do
      loop(:trial_signals)
    end
    """
  end

  @doc """
  `.pred` source: a pipeline mixing an inline loop (one cross-file predicate
  reference plus an inline DateTime predicate) with a cross-file loop
  reference. Resolvable only against the full corpus.
  """
  @spec complex_source() :: String.t()
  def complex_source do
    """
    pipeline(:complex_pipeline, "Complex processing pipeline") do
      loop(:signal_detection, "Signal detection loop") do
        predicate(:active)

        predicate(:new_user, "New user detection") do
          fn item ->
            created_at = item.fields["created_at"]
            now = DateTime.utc_now() |> DateTime.to_unix()
            created_unix = DateTime.from_iso8601(created_at)
                        |> elem(1)
                        |> DateTime.to_unix()
            now - created_unix < 86400 * 30 # Less than 30 days
          end
        end
      end

      loop(:trial_signals)
    end
    """
  end
end
