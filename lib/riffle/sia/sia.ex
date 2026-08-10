defmodule Riffle.Sia do
  @moduledoc """
  THE pattern layer: a staged run over the waist.

      run(ctx, pipeline, input) -> {ctx', emissions}

  This is the edge where the two independent halves of Riffle meet. The engine
  evaluates predicates and is impure -- evaluation reaches a cache owned by a
  process -- so it cannot live inside the knot. The waist is pure and knows
  nothing of who consumes it. `Riffle.Sia` names both; neither names it, and
  the boundary fence holds that in every direction.

  ## A stage is a loop

  The pipeline's loop sequence *is* the staging. A stage's identity is the
  loop's own name, read off the struct -- there is no stage registry, no
  mapping table, and no convention parsed out of tag prefixes. Sense, infer and
  act are then a three-loop pipeline whose loops are named for the three
  stages, which makes the shipped definitions an instance of the pattern rather
  than a shape this module imposes. A four-stage pipeline runs without a line
  changing here.

  ## The run

  Each stage is bracketed by typed perturbations applied to `Riffle.Ctx.Knot`,
  and the only impure step -- evaluating the loop -- happens strictly between
  two of them, never inside one:

      RunStarted -> InputReceived
        -> per loop: StageEntered -> (evaluate) -> StageProgressed -> StageExited
        -> MetadataRecorded -> RunCompleted

  Results are returned, not stashed. `run/3` hands back the final context and
  the emissions in firing order; what to do with them is the caller's business.

  ## Why the shape is this careful

  The layer this replaces computed correct results, materialised them to derive
  tag counts, discarded them, and recorded `results_available: true`. The flag
  was not stale -- it was false the moment it was written. Its tests read a
  structural default and could not see it.

  So a completed run puts its results in three places that must agree: the
  final stage's `StageCompleted` output, the `OutputProduced` payload, and
  `ctx.output`. And the one statistic recorded here is a projection of facts
  already emitted rather than a tally kept beside them, because a tally that
  can outlive its evidence is precisely what went wrong. Both are fenced in
  `test/riffle/sia/evidence_fence_test.exs`.

  Nothing is swallowed: there is no `rescue` in this layer, and an exception
  from a predicate leaves a run with its type and message intact.
  """

  alias Riffle.Ctx
  alias Riffle.Ctx.Emission
  alias Riffle.Ctx.Knot
  alias Riffle.Ctx.Perturbation
  alias Riffle.Predicate.Item
  alias Riffle.Predicate.Loop
  alias Riffle.Predicate.Pipeline

  @metadata_keys [:stage_counts]

  # The accumulator threaded through a run: the context, the emissions so far,
  # and the items still alive after the last stage.
  @typep run_state :: {Ctx.t(), [Emission.t()], [Item.t()]}

  @doc """
  The metadata keys a run may record.

  Declared, closed, and fenced: a `MetadataSet` naming anything else fails the
  build. Adding a key here means also making it recomputable from the run's own
  emissions, which is what keeps a statistic from outliving its evidence.
  """
  @spec metadata_keys() :: [atom()]
  def metadata_keys, do: @metadata_keys

  @doc """
  Runs `input` through `pipeline`, one stage per loop, threading `ctx`.

  Returns the final context and every emission the run produced, in firing
  order. The context is supplied by the caller rather than minted here, so the
  run id -- and any metadata the caller seeded -- comes from outside.

  `input` is an enumerable of field maps or `Riffle.Predicate.Item` structs.
  Ingest is eager and total over those two shapes; anything else raises naming
  what arrived, before the first perturbation is applied.

  ## Examples

      iex> alias Riffle.{Ctx, Predicate, Predicate.Loop, Predicate.Pipeline, Sia}
      iex> loop = Loop.new(:doc_active, "Active", [Predicate.new(:doc_active_p, "Active", fn item -> item.fields["status"] == "active" end)])
      iex> pipeline = Pipeline.new(:doc, "One stage", [loop])
      iex> {ctx, _emissions} = Sia.run(Ctx.new(run_id: "doc"), pipeline, [%{"status" => "active"}, %{"status" => "idle"}])
      iex> {ctx.status, length(ctx.output), hd(ctx.output).tags}
      {:completed, 1, [:doc_active_p]}
  """
  @spec run(Ctx.t(), Pipeline.t(), Enumerable.t()) :: {Ctx.t(), [Emission.t()]}
  def run(%Ctx{} = ctx, %Pipeline{} = pipeline, input) do
    items = ingest(input)

    {ctx, [], items}
    |> perturb(%Perturbation.RunStarted{})
    |> perturb(%Perturbation.InputReceived{payload: items})
    |> stage(pipeline.loops)
    |> record_counts()
    |> complete()
  end

  # -- ingest -----------------------------------------------------------------

  # Eager, so a run cannot report success over input it never converted. The
  # item clause comes first: a struct is a map, and reversing these two would
  # rebuild every item that arrived already built.
  defp ingest(input), do: Enum.map(input, &to_item/1)

  defp to_item(%Item{} = item), do: item
  defp to_item(%{} = fields), do: Item.create(fields)

  defp to_item(other) do
    raise ArgumentError,
          "cannot ingest #{inspect(other)} -- a run takes field maps or " <>
            "#{inspect(Item)} structs"
  end

  # -- staging ----------------------------------------------------------------

  @spec stage(run_state(), [Loop.t()]) :: run_state()
  defp stage(state, loops), do: Enum.reduce(loops, state, &stage_one/2)

  defp stage_one(%Loop{} = loop, state) do
    entered = perturb(state, %Perturbation.StageEntered{stage: loop.name})
    received = items(entered)
    retained = loop |> Loop.filter(received) |> Enum.to_list()

    entered
    |> perturb(progressed(loop, received, retained))
    |> perturb(%Perturbation.StageExited{stage: loop.name, output: retained})
    |> advance(retained)
  end

  defp progressed(%Loop{} = loop, received, retained) do
    %Perturbation.StageProgressed{
      stage: loop.name,
      progress: %{received: length(received), retained: length(retained)}
    }
  end

  # -- the record -------------------------------------------------------------

  # The statistic is a projection of facts the run has already emitted, not a
  # parallel tally. A tally kept beside the results is the shape that let a
  # count outlive the collection it counted.
  defp record_counts({_ctx, emissions, _items} = state) do
    perturb(state, %Perturbation.MetadataRecorded{
      key: :stage_counts,
      value: stage_counts(emissions)
    })
  end

  defp stage_counts(emissions) do
    for %Emission.StageCompleted{stage: stage, output: output} <- emissions,
        do: {stage, length(output)}
  end

  defp complete({_ctx, _emissions, items} = state) do
    {ctx, emissions, _items} = perturb(state, %Perturbation.RunCompleted{output: items})

    {ctx, emissions}
  end

  # -- threading --------------------------------------------------------------

  @spec perturb(run_state(), Perturbation.t()) :: run_state()
  defp perturb({ctx, emissions, items}, perturbation) do
    {next, produced} = Knot.tick(ctx, perturbation)

    {next, emissions ++ produced, items}
  end

  defp items({_ctx, _emissions, items}), do: items

  defp advance({ctx, emissions, _items}, items), do: {ctx, emissions, items}
end
