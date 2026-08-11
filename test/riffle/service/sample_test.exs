defmodule Riffle.Service.SampleTest do
  use ExUnit.Case, async: true

  alias Riffle.Service

  # The shipped sample has to match the shipped definitions, and nothing
  # mechanical would otherwise notice if it stopped.
  #
  # The archived project's `users.csv` carried `user_id,email,last_login_date,
  # account_status,login_count`, while the predicates shipped beside it read
  # `@login_count`, `@days_since_login`, `@account_type` and
  # `@subscription_status`. Three of those four columns are absent and a fourth
  # is spelled differently, so a run over it tags nothing -- and every count
  # would still be a perfectly valid number. A first run that quietly produces
  # an empty result is the worst possible introduction to a tool, because it
  # looks like the tool works and the user's data is boring.

  defp pred, do: Path.join(:code.priv_dir(:riffle), "sia/sia.pred")
  defp sample, do: Path.join(:code.priv_dir(:riffle), "sia/sample.csv")

  test "invariant: the shipped sample runs the shipped pipeline to a non-empty result" do
    {:ok, result} = Service.run(input: sample(), source: {:file, pred()}, pipeline: :main)

    assert result.output_count > 0
    refute Enum.any?(result.stages, fn {_stage, kept} -> kept == 0 end)
  end

  test "invariant: surviving items carry concrete tags from every stage" do
    {:ok, result} = Service.run(input: sample(), source: {:file, pred()}, pipeline: :main)

    tags = result.ctx.output |> Enum.flat_map(& &1.tags) |> Enum.uniq() |> Enum.sort()

    assert tags == [
             :action_create_upsell,
             :action_send_promotion,
             :inference_high_value_user,
             :inference_upsell_opportunity,
             :signal_churn_risk,
             :signal_high_activity,
             :signal_premium_account
           ]
  end

  test "invariant: the sample exercises attrition rather than passing everything through" do
    # A sample every row survives would prove the runner returns its input, not
    # that the predicates discriminate.
    {:ok, result} = Service.run(input: sample(), source: {:file, pred()}, pipeline: :main)

    assert result.input_count > result.output_count
    assert result.stages == [signal_loop: 9, inference_loop: 6, action_loop: 6]
  end

  test "invariant: the sample's columns are exactly what the shipped predicates read" do
    [header | _rows] = sample() |> File.read!() |> String.split("\n", trim: true)

    assert String.split(header, ",") |> Enum.sort() == [
             "account_type",
             "days_since_login",
             "login_count",
             "subscription_status"
           ]
  end
end
