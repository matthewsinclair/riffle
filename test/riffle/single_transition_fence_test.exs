defmodule Riffle.SingleTransitionFenceTest do
  use ExUnit.Case, async: true

  alias Riffle.FenceHelpers

  # Bedrock commitment 3: the context exposes reads and construction, and the
  # one way to change it is to apply a perturbation. Until this thread nothing
  # existed that could violate that, so it held by inspection. The pattern layer
  # is the first consumer with a context in hand and a reason to reach in.
  #
  # Two clauses, because there are two ways to reach in and they look nothing
  # alike in the AST:
  #
  #   1. `%Riffle.Ctx{ctx | status: :done}` -- the explicit form. Fenced across
  #      the whole library, outside the waist.
  #   2. `%{ctx | status: :done}` -- the bare form, which is what the knot
  #      itself uses and what anyone reaching in would reach for. It carries no
  #      type, so it cannot be fenced by naming Ctx; it is fenced by forbidding
  #      map update outright inside the pattern layer, which is a thin
  #      coordinator with no business updating a map at all.
  #
  # Update syntax is distinguishable from construction and from pattern
  # matching: it is the form carrying `|` inside the map. So `%Ctx{} = ctx` in a
  # function head stays legal, which matters -- a fence that banned that would
  # be turned off within a week.

  test "fence: no Riffle.Ctx struct-update expression exists outside the waist" do
    sources = FenceHelpers.library_sources() -- FenceHelpers.waist_sources()

    assert sources != []

    offending = Enum.filter(sources, &Enum.any?(struct_updates(&1), fn t -> waist?(t) end))

    assert offending == []
  end

  test "fence: the pattern layer updates no map at all" do
    sources = FenceHelpers.pattern_layer_sources()

    assert sources != []

    offending = Enum.filter(sources, &(map_updates(&1) > 0))

    assert offending == []
  end

  test "invariant: the walk sees both update forms and neither construction nor match" do
    # The positive control, and the negative one. A fence built on AST shape can
    # go dead by matching a form that no longer occurs, and it can go useless by
    # matching everything -- both halves are checked here.
    updates =
      probe("""
        alias Riffle.Ctx

        def run(ctx) do
          _fully_qualified = %Riffle.Ctx{ctx | status: :running}
          _aliased = %Ctx{ctx | status: :running}
          _bare_update = %{ctx | status: :running}
        end
      """)

    inert =
      probe("""
        def run(%Riffle.Ctx{} = ctx) do
          _construction = %Riffle.Ctx{run_id: "r"}
          _plain_map = %{status: :running}
          ctx
        end
      """)

    found =
      {struct_updates(updates), map_updates(updates), struct_updates(inert), map_updates(inert)}

    File.rm!(updates)
    File.rm!(inert)

    # Both spellings of the struct update are seen -- the aliased form is the
    # one a text scan and a naive AST match would both miss, and it is the form
    # anyone reaching in would actually write. Construction and pattern match
    # are seen by neither walk.
    assert {targets, 3, [], 0} = found
    assert Enum.all?(targets, &waist?/1)
    assert length(targets) == 2
  end

  # The struct-update form: %Alias{var | ...}. The alias is what makes it
  # nameable, so it is what comes back.
  defp struct_updates(path) do
    {_ast, found} =
      path |> read_ast() |> Macro.prewalk([], &collect_struct_update/2)

    Enum.uniq(found)
  end

  # Every map update, struct-typed or not. Counted rather than named, because
  # the bare form has nothing to name.
  defp map_updates(path) do
    {_ast, found} = path |> read_ast() |> Macro.prewalk(0, &collect_map_update/2)

    found
  end

  defp read_ast(path), do: path |> File.read!() |> Code.string_to_quoted!()

  # `%Ctx{ctx | ...}` and `%Riffle.Ctx{ctx | ...}` are the same reach-in written
  # two ways, and an alias is resolved at compile time, not in this AST. The
  # final segment settles it -- `Ctx` is the only module in the project whose
  # name ends there, so matching on it is total over both spellings.
  defp waist?(target), do: last_segment(target) == last_segment(FenceHelpers.waist_namespace())

  defp last_segment(dotted), do: dotted |> String.split(".") |> List.last()

  defp collect_struct_update(
         {:%, _, [{:__aliases__, _, segments}, {:%{}, _, [{:|, _, _}]}]} = node,
         acc
       ),
       do: {node, [Enum.join(segments, ".") | acc]}

  defp collect_struct_update(node, acc), do: {node, acc}

  defp collect_map_update({:%{}, _, [{:|, _, _}]} = node, acc), do: {node, acc + 1}
  defp collect_map_update(node, acc), do: {node, acc}

  defp probe(body) do
    path =
      Path.join(
        System.tmp_dir!(),
        "riffle_transition_probe_#{System.unique_integer([:positive])}.ex"
      )

    File.write!(path, "defmodule Probe do\n#{body}end\n")

    path
  end
end
