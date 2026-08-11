defmodule Riffle do
  @moduledoc """
  Riffle runs data streams over composable predicate pipelines.

  Each item flows through a sequence of stages. A stage keeps the items at
  least one of its predicates matches, and tags them as it goes, so what
  reaches the next stage is narrower than what arrived and carries a record of
  why it survived. The predicates are the riffles: the stream passes through
  unimpeded, and what matters gets caught.

  ## A stage is a loop

  A pipeline is a sequence of loops, and the runner takes each loop as one
  stage. Nothing decides how many stages there are except the pipeline: one
  loop is one stage, four loops are four stages, and no code changes between
  those two cases.

  The definitions Riffle ships happen to declare three loops -- `signal_loop`,
  `inference_loop`, `action_loop` -- because sense, infer and act is the
  pattern they encode. That is what those definitions say, not a shape the
  runner imposes, and a stage's identity is its loop's own name rather than
  anything parsed out of the tags its predicates apply.

  ## The layers

  Five, and the architecture is which of them may name which. Each names the
  one below it and is named by none of them; every clause of that is held by a
  conformance fence in the test suite rather than by convention.

    * `Riffle.Predicate` -- the engine. Evaluates predicates, loops and
      pipelines, defined in Elixir or loaded from `.pred` files. Names nothing
      else.
    * `Riffle.Ctx` -- the waist. A bowtie: typed perturbations fan in, a pure
      total knot (`Riffle.Ctx.Knot.tick/2`) turns each into new state plus
      typed emissions, and those fan out. Names nothing else.
    * `Riffle.Sia` -- the pattern layer. The edge where the two compose: it
      stages a pipeline loop by loop, evaluating at the edge and applying each
      result to the knot. Names both, and neither names it.
    * `Riffle.Service` -- the way in. Reads rows, runs a pipeline, reports what
      happened. Names no CLI framework, so the library is usable without one.
    * `Riffle.Cli` -- thin coordinators over the service. May name no engine,
      waist or pattern-layer module at all.

  ## Running one

      {:ok, result} =
        Riffle.Service.run(
          input: "data.csv",
          source: {:file, "definitions.pred"},
          pipeline: :main
        )

  `result.stages` is one entry per loop, under that loop's own name;
  `result.ctx.output` is the surviving items, tagged; `result.emissions` is the
  full evidence of the run. `Riffle.Sia.run/4` is one level below that, for a
  caller who already has rows.

  From a shell, `riffle sia.run --input data.csv --from definitions.pred`.

  ## Where to read next

    * `Riffle.Service` -- the entry point, and the error vocabulary
    * `Riffle.Sia` -- how a run is staged through the knot
    * `Riffle.Ctx` -- the waist, and the two catalogs that type it
    * `Riffle.Predicate` -- predicates, loops and pipelines
    * `Riffle.Predicate.Dsl.Parser` -- the `.pred` file grammar

  The architectural commitments, and the fence enforcing each, are in
  `intent/docs/bedrock.md`. A contradiction with that document is a bug in the
  contradicting document.
  """
end
