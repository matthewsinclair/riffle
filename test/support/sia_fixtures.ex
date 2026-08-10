defmodule Riffle.SiaFixtures do
  @moduledoc """
  The one home for the pattern layer's test inputs (test-highlander).

  Two shapes, and they are deliberately different things. The **staging**
  pipeline is small, arithmetic, and exists to make the mechanics of a staged
  run legible: six numbers, two loops, a retained count that changes at each
  stage. The **characterisation** input is the four rows the archived
  characterisation tests ran on, carried over unchanged so the assertions this
  thread strengthens are strengthened against the same data.

  Predicate names carry a `sia_fixture_` prefix because the evaluation cache is
  global and keyed on the predicate's name: a fixture sharing a name with
  another suite's predicate would serve that suite's answer.
  """

  alias Riffle.Predicate
  alias Riffle.Predicate.Loop
  alias Riffle.Predicate.Pipeline

  @doc """
  A two-stage pipeline over a single numeric field.

  Stage `:sia_fixture_even` keeps even numbers; stage `:sia_fixture_big` keeps
  numbers above four. Over `staging_input/0` that is 6 items in, 3 retained,
  then 1 -- so a run's counts differ at every stage and a fence comparing them
  cannot pass by coincidence.
  """
  @spec staging_pipeline() :: Pipeline.t()
  def staging_pipeline do
    Pipeline.new(:sia_fixture_staging, "Two stages over one numeric field", [
      Loop.new(:sia_fixture_even, "Even numbers", [
        Predicate.new(:sia_fixture_even_n, "n is even", &even?/1)
      ]),
      Loop.new(:sia_fixture_big, "Numbers above four", [
        Predicate.new(:sia_fixture_big_n, "n is above four", &big?/1)
      ])
    ])
  end

  @doc "A single-stage pipeline, for runs that must have exactly one stage."
  @spec single_stage_pipeline() :: Pipeline.t()
  def single_stage_pipeline do
    Pipeline.new(:sia_fixture_single, "One stage", [
      Loop.new(:sia_fixture_even, "Even numbers", [
        Predicate.new(:sia_fixture_even_n, "n is even", &even?/1)
      ])
    ])
  end

  @doc "A pipeline with no loops at all, for the stageless run."
  @spec stageless_pipeline() :: Pipeline.t()
  def stageless_pipeline, do: Pipeline.new(:sia_fixture_stageless, "No stages", [])

  @doc "A pipeline whose only predicate raises, for proving the layer swallows nothing."
  @spec raising_pipeline() :: Pipeline.t()
  def raising_pipeline do
    Pipeline.new(:sia_fixture_raising, "One stage that raises", [
      Loop.new(:sia_fixture_raises, "Raises on every item", [
        Predicate.new(:sia_fixture_raises_n, "always raises", &raise_on/1)
      ])
    ])
  end

  @doc "Six items, `n` running 1 to 6, as field maps."
  @spec staging_input() :: [map()]
  def staging_input, do: for(n <- 1..6, do: %{"n" => Integer.to_string(n)})

  @doc "The four rows the archived characterisation tests ran on."
  @spec characterisation_input() :: [map()]
  def characterisation_input do
    [
      %{
        "login_count" => "100",
        "days_since_login" => "5",
        "account_type" => "standard",
        "subscription_status" => "active"
      },
      %{
        "login_count" => "20",
        "days_since_login" => "40",
        "account_type" => "premium",
        "subscription_status" => "active"
      },
      %{
        "login_count" => "120",
        "days_since_login" => "3",
        "account_type" => "premium",
        "subscription_status" => "active"
      },
      %{
        "login_count" => "5",
        "days_since_login" => "90",
        "account_type" => "standard",
        "subscription_status" => "inactive"
      }
    ]
  end

  defp even?(item), do: rem(n(item), 2) == 0
  defp big?(item), do: n(item) > 4
  defp raise_on(item), do: raise(RuntimeError, "predicate raised on n=#{n(item)}")
  defp n(item), do: item.fields |> Map.fetch!("n") |> String.to_integer()
end
