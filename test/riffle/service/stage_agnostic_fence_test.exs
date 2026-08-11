defmodule Riffle.Service.StageAgnosticFenceTest do
  use ExUnit.Case, async: true

  alias Riffle.Service
  alias Riffle.ServiceFixtures

  # The fence this thread exists for.
  #
  # ST0003 DD-2 settled that a stage IS a loop and that a stage's identity is
  # the loop's own name -- no registry, no behaviour, no naming convention
  # parsed out of tags. The archived CLI contradicted it at the one place a
  # person actually looks: it recovered stage membership with
  # `get_tags_with_prefix(item, "signal_")` and wrote three fixed columns,
  # `signal_tags` / `inference_tags` / `action_tags`. Riffle ships three loops
  # with those exact prefixes, so every test written against the shipped
  # pipeline would have passed while the claim in the README -- "a pipeline with
  # four of them runs as four stages with no code change" -- was false.
  #
  # This is a whole-class assertion, not an example: it runs a pipeline that
  # shares nothing with the shipped one -- four loops instead of three, names
  # following no convention, and loop names deliberately different from the
  # predicate names inside them -- and requires the summary to name those four
  # loops, in order, with their own names.
  #
  # Mutating the service to slice the summary to three entries, to hardcode the
  # shipped names, or to rebuild it from item tags takes this red.

  test "fence: a four-loop pipeline summarises as four stages under its own loop names" do
    input = ServiceFixtures.numeric_csv!(1..6)

    {:ok, result} =
      Service.run(input: input, source: ServiceFixtures.four_loop_pipeline())

    assert result.stages == [zeroth: 6, widget_check: 3, q3: 2, final_gate: 2]
  end

  test "fence: the summary carries loop names, not the names of the predicates inside them" do
    input = ServiceFixtures.numeric_csv!(1..6)

    {:ok, result} = Service.run(input: input, source: ServiceFixtures.four_loop_pipeline())

    reported = Keyword.keys(result.stages)
    tagged = result.ctx.output |> Enum.flat_map(& &1.tags) |> Enum.uniq()

    # The two vocabularies are disjoint by construction in the fixture, so a
    # summary rebuilt from tags could not accidentally agree with this.
    assert reported == [:zeroth, :widget_check, :q3, :final_gate]
    assert tagged != []
    assert Enum.all?(reported, &(&1 not in tagged))
  end

  test "invariant: the counts are the real per-stage survivor counts, not a fixed shape" do
    # Guards against the summary being right in arity but wrong in content --
    # four entries whose numbers came from somewhere else. Each count must equal
    # the length of that stage's own recorded output.
    input = ServiceFixtures.numeric_csv!(1..6)

    {:ok, result} = Service.run(input: input, source: ServiceFixtures.four_loop_pipeline())

    evidence =
      for %Riffle.Ctx.Emission.StageCompleted{stage: stage, output: output} <- result.emissions,
          do: {stage, length(output)}

    assert result.stages == evidence
    assert result.output_count == 2
    assert result.input_count == 6
  end
end
