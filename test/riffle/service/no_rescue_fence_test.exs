defmodule Riffle.Service.NoRescueFenceTest do
  use ExUnit.Case, async: true

  alias Riffle.FenceHelpers
  alias Riffle.Service
  alias Riffle.ServiceFixtures

  # The same D9 defect the pattern layer is fenced against, at a boundary where
  # the answer cannot be "never rescue".
  #
  # The service reads a file a person chose. A malformed CSV is an ordinary
  # outcome to report, not a defect to crash on, so `Riffle.Service.Csv` does
  # convert a parse failure into a tagged error -- exactly as the engine's
  # `Dsl.Loader` already does for `.pred` text. Forbidding the keyword outright
  # would forbid the correct thing along with the wrong one.
  #
  # So this fence forbids the SHAPE that caused D9 rather than the keyword: the
  # rescue-all. `rescue _ ->` and `rescue e ->` catch every exception from
  # anywhere and make a crash indistinguishable from a handled outcome. A
  # rescue that names its exception type handles one thing and lets everything
  # else through, which is the whole difference.
  #
  # `catch` and `after` stay banned outright -- neither has a boundary argument.

  test "fence: every rescue in the service layer names its exception type" do
    sources = FenceHelpers.service_sources()

    assert sources != []

    offending = Enum.filter(sources, &(untyped_rescues(&1) != []))

    assert offending == []
  end

  test "fence: the service layer contains no catch or after" do
    sources = FenceHelpers.service_sources()

    assert sources != []

    offending = Enum.filter(sources, &(swallowing_forms(&1) != []))

    assert offending == []
  end

  test "invariant: the walk tells a typed rescue from a rescue-all" do
    # The positive control, and it has to run in both directions. A walk that
    # called everything typed would pass the fence above forever; a walk that
    # called everything untyped would fail on the one rescue the layer is
    # allowed, and someone would 'fix' it by deleting the fence.
    bare = probe("def run do\n    :ok\n  rescue\n    _ -> :ok\n  end")
    bound = probe("def run do\n    :ok\n  rescue\n    e -> e\n  end")
    typed = probe("def run do\n    :ok\n  rescue\n    e in ArgumentError -> e\n  end")
    by_type = probe("def run do\n    :ok\n  rescue\n    ArgumentError -> :ok\n  end")
    cleanup = probe("def run do\n    try do\n      :ok\n    after\n      :ok\n    end\n  end")

    found = %{
      bare: untyped_rescues(bare),
      bound: untyped_rescues(bound),
      typed: untyped_rescues(typed),
      by_type: untyped_rescues(by_type),
      cleanup: swallowing_forms(cleanup)
    }

    Enum.each([bare, bound, typed, by_type, cleanup], &File.rm!/1)

    assert found.bare != []
    assert found.bound != []
    assert found.typed == []
    assert found.by_type == []
    assert found.cleanup == [:after]
  end

  test "failure: an exception in predicate evaluation propagates out of the service" do
    input = ServiceFixtures.numeric_csv!(1..1)

    assert_raise RuntimeError, "predicate raised on n=1", fn ->
      Service.run(input: input, source: ServiceFixtures.raising_pipeline())
    end
  end

  defp untyped_rescues(path) do
    path
    |> walk(&collect_rescue/2)
    |> Enum.reject(&typed?/1)
  end

  defp swallowing_forms(path) do
    path |> walk(&collect_swallow/2) |> Enum.uniq()
  end

  defp walk(path, collector) do
    {_ast, found} =
      path
      |> File.read!()
      |> Code.string_to_quoted!()
      |> Macro.prewalk([], collector)

    found
  end

  defp collect_rescue({:rescue, clauses} = node, acc) when is_list(clauses),
    do: {node, Enum.map(clauses, &pattern_of/1) ++ acc}

  defp collect_rescue(node, acc), do: {node, acc}

  defp pattern_of({:->, _meta, [[pattern], _body]}), do: pattern

  # `e in SomeError` and a bare `SomeError` both name what they handle; a
  # variable or an underscore names nothing and takes everything.
  defp typed?({:in, _meta, [_binding, _types]}), do: true
  defp typed?({:__aliases__, _meta, _segments}), do: true
  defp typed?(_pattern), do: false

  defp collect_swallow({key, _handlers} = node, acc) when key in [:catch, :after],
    do: {node, [key | acc]}

  defp collect_swallow(node, acc), do: {node, acc}

  defp probe(body) do
    path =
      Path.join(
        System.tmp_dir!(),
        "riffle_service_rescue_probe_#{System.unique_integer([:positive])}.ex"
      )

    File.write!(path, "defmodule Probe do\n  #{body}\nend\n")

    path
  end
end
