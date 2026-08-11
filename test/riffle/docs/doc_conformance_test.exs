defmodule Riffle.Docs.DocConformanceTest do
  use ExUnit.Case, async: true

  alias Riffle.Ctx.Emission
  alias Riffle.Ctx.Perturbation
  alias Riffle.DocHelpers

  # Documentation drifts from code silently, because nothing runs it. These
  # fences run what can be run.
  #
  # The thread that added them found the root `Riffle` moduledoc -- the module
  # named after the project, and the first page a reader meets -- teaching
  # "three tag-driven stages" identified by tag prefixes. That is the model
  # ST0003 DD-2 refuted (a stage is a loop, and its identity is the loop's own
  # name) and ST0004 DD-7 fenced out of the CLI. The README had been corrected
  # and bedrock.md was right; the moduledoc taught the wrong thing anyway,
  # which is the same shape as ST0002's "reference implementation" claim
  # surviving in the README: a ruling applied in most places, not all.
  #
  # The walks live in Riffle.DocHelpers (test/support), where branching code
  # belongs.

  @catalogs [Emission, Perturbation]

  describe "references resolve" do
    test "fence: every fun/arity reference in every doc points at something that exists" do
      stale =
        DocHelpers.modules()
        |> Enum.flat_map(&DocHelpers.references/1)
        |> Enum.reject(&DocHelpers.resolves?/1)

      assert stale == []
    end

    test "invariant: the scan finds references, and would report a broken one" do
      # Positive control in both directions. A scan that found nothing would
      # pass the fence above forever; a resolver that accepted anything would
      # too.
      assert DocHelpers.references(Riffle) != []
      refute DocHelpers.resolves?({Riffle, "moduledoc", Riffle, "no_such_function", 3})
      assert DocHelpers.resolves?({Riffle, "moduledoc", Riffle.Service, "run", 1})
    end
  end

  describe "the typed vocabulary documents itself" do
    test "fence: every catalog member's doc describes each of its own payload fields" do
      undescribed =
        for module <- catalog_members(),
            field <- DocHelpers.struct_fields(module),
            not (module |> DocHelpers.moduledoc() |> String.contains?("`#{field}`")),
            do: {module, field}

      assert undescribed == []
    end

    test "fence: no catalog member is left with a one-line doc" do
      # These twenty modules ARE the public vocabulary of the waist. A reader
      # has to be able to tell StageProgress from StageCompleted -- the
      # distinction the D2 defect turned on -- from the docs alone.
      thin =
        for module <- catalog_members(),
            lines = module |> DocHelpers.moduledoc() |> String.split("\n") |> length(),
            lines < 4,
            do: {module, lines}

      assert thin == []
    end

    test "invariant: the catalogs are non-empty and the walk reads real docs" do
      members = catalog_members()

      assert length(members) == 20
      assert Emission.StageProgress in members
      assert DocHelpers.moduledoc(Emission.StageProgress) =~ "progress"
      assert DocHelpers.struct_fields(Emission.StageProgress) == [:progress, :stage]
    end
  end

  describe "documented examples are checked examples" do
    test "fence: every module with an example in its docs has a doctest running it" do
      # An `iex>` line that no `doctest` declaration picks up is not an
      # example, it is a claim. Five modules were in that state when this was
      # written -- 44 lines between them -- and three of the five were wrong:
      # `Cache` documented `{:ok, _pid} = start_link()` for a process the
      # supervisor has already started, and both `Cache` and `Evaluator`
      # carried examples that did not even compile.
      declared = DocHelpers.declared_doctests()

      unchecked =
        for module <- DocHelpers.modules(),
            count = DocHelpers.examples(module),
            count > 0,
            inspect(module) not in declared,
            do: {module, count}

      assert unchecked == []
    end

    test "invariant: the declaration scan and the example count both see real data" do
      assert "Riffle.Predicate.Dsl.Evaluator" in DocHelpers.declared_doctests()
      assert DocHelpers.examples(Riffle.Predicate.Dsl.Evaluator) > 0
      assert DocHelpers.examples(Riffle.Ctx.Catalog) == 0
    end
  end

  describe "the architecture the docs teach" do
    test "fence: no doc describes stages as driven by tag prefixes" do
      # `signal_loop` is a real loop name in the shipped definitions and is
      # fine anywhere. The glob forms below appear only when something is
      # claiming that a prefix is what makes a stage -- the refuted model, and
      # exactly the notation the old root moduledoc used.
      offenders =
        for module <- DocHelpers.modules(),
            doc = DocHelpers.moduledoc(module),
            pattern <- ~w(signal_* inference_* action_*),
            String.contains?(doc, pattern),
            do: {module, pattern}

      assert offenders == []
    end

    test "invariant: the walk would catch the phrasing it is looking for" do
      assert String.contains?("predicates named signal_* detect patterns", "signal_*")
    end
  end

  describe "generated API is documented API" do
    test "fence: a module built from the DSL exposes no undocumented function" do
      # One accessor per predicate, loop and pipeline is generated. Before
      # ST0005 they arrived bare, so the shipped example module's page was 13
      # undocumented entries; they now carry each definition's own description.
      assert DocHelpers.undocumented(Riffle.Sia.DefaultPipeline) == []
    end

    test "invariant: the shipped module really does generate accessors" do
      # ensure_loaded! first: function_exported?/3 answers false for a module
      # that simply has not been loaded yet, which would make this control pass
      # for the wrong reason and then fail confusingly.
      Code.ensure_loaded!(Riffle.Sia.DefaultPipeline)

      assert function_exported?(Riffle.Sia.DefaultPipeline, :signal_high_activity, 0)
      assert length(Riffle.Sia.DefaultPipeline.list_pipelines()) == 3
    end
  end

  defp catalog_members, do: @catalogs |> Enum.flat_map(& &1.implementations()) |> Enum.sort()
end
