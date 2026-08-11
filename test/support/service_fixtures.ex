defmodule Riffle.ServiceFixtures do
  @moduledoc """
  Shared inputs for the service and CLI suites.

  Temp files and the multi-loop pipeline live here rather than in each suite
  because three suites need them, and ST0003 already paid for learning what
  happens when that setup is copied instead: the copies drift, and a fence
  built on a drifted fixture proves something nobody intended (IN-EX-TEST-007).

  Predicate names carry a `svc_` prefix. The evaluation cache keys on a
  predicate's *name*, so a fixture sharing a name with another suite's would
  share its cached verdicts too.
  """

  alias Riffle.Predicate
  alias Riffle.Predicate.Loop
  alias Riffle.Predicate.Pipeline

  @doc """
  Writes `contents` to a uniquely-named temp CSV and removes it after the test.
  """
  @spec write_csv!(String.t()) :: Path.t()
  def write_csv!(contents) do
    path =
      Path.join(
        System.tmp_dir!(),
        "riffle_service_#{System.unique_integer([:positive])}.csv"
      )

    File.write!(path, contents)
    ExUnit.Callbacks.on_exit(fn -> File.rm_rf!(path) end)
    path
  end

  @doc """
  A CSV of one column `n`, carrying `range`, header included.
  """
  @spec numeric_csv!(Enumerable.t()) :: Path.t()
  def numeric_csv!(range) do
    write_csv!(Enum.join(["n" | Enum.map(range, &to_string/1)], "\n") <> "\n")
  end

  @doc """
  A pipeline of FOUR loops whose names follow no convention.

  The point of it is everything the shipped definitions are not. Riffle ships
  three loops named `signal_loop` / `inference_loop` / `action_loop`, and a
  summary that quietly assumed that shape -- three stages, or names recovered by
  parsing a `signal_` tag prefix, which is what the archived CLI did -- would
  pass every test written against the shipped pipeline and be wrong for
  everyone else's.

  So: four loops, arbitrary names, and loop names deliberately unequal to the
  names of the predicates inside them. A summary reconstructed from tags would
  report the predicate names and miss.

  Over `n` in 1..6 the loops cut 6 -> 3 -> 2 -> 2.
  """
  @spec four_loop_pipeline() :: Pipeline.t()
  def four_loop_pipeline do
    Pipeline.new(:svc_four, "Four loops, arbitrary names", [
      Loop.new(:zeroth, "Everything positive", [predicate(:svc_positive, &(&1 > 0))]),
      Loop.new(:widget_check, "Even only", [predicate(:svc_even, &(rem(&1, 2) == 0))]),
      Loop.new(:q3, "Greater than two", [predicate(:svc_gt_two, &(&1 > 2))]),
      Loop.new(:final_gate, "Under a hundred", [predicate(:svc_lt_hundred, &(&1 < 100))])
    ])
  end

  @doc "A pipeline whose single predicate raises, for propagation tests."
  @spec raising_pipeline() :: Pipeline.t()
  def raising_pipeline do
    Pipeline.new(:svc_raising, "Raises", [
      Loop.new(:boom, "Raises", [
        Predicate.new(:svc_raises, "Raises", fn item ->
          raise RuntimeError, "predicate raised on n=#{n(item)}"
        end)
      ])
    ])
  end

  defp predicate(name, test) do
    Predicate.new(name, Atom.to_string(name), fn item -> test.(n(item)) end)
  end

  defp n(item), do: item.fields |> Map.fetch!("n") |> String.to_integer()
end
