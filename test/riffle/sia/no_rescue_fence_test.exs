defmodule Riffle.Sia.NoRescueFenceTest do
  use ExUnit.Case, async: true

  alias Riffle.Ctx
  alias Riffle.FenceHelpers
  alias Riffle.Sia
  alias Riffle.SiaFixtures

  # D9 in the ledger: the source layer wrapped its whole execution path in a
  # rescue that turned every exception -- any exception, from anywhere -- into
  # one opaque tag, logged at debug level only. A pipeline that crashed and a
  # pipeline that legitimately matched nothing were indistinguishable to a
  # caller, and the difference was visible only to someone reading debug logs.
  #
  # The fence is structural because the behavioural test can only prove the one
  # path it walks. `rescue` is also not a word a text scan can be trusted with:
  # it appears in comments and in strings, and a function-body `rescue` is not
  # syntactically a `try` at all. Both forms are read off the parsed AST.
  #
  # The engine's Loader does convert raises to tagged errors, and that stays:
  # `.pred` content is user input, the conversion sits at exactly that boundary,
  # and it names the one failure it handles. This fence is scoped to the layer.

  @swallowing_forms [:rescue, :catch, :after]

  test "fence: the pattern layer contains no rescue, catch or after" do
    sources = FenceHelpers.pattern_layer_sources()

    assert sources != []

    offending = Enum.filter(sources, &(swallowing_forms(&1) != []))

    assert offending == []
  end

  test "invariant: the walk sees both the try form and the function-body form" do
    # The positive control. Without it this fence goes dead the moment the AST
    # shape it matches stops occurring, and still passes -- which is exactly how
    # a fence in the previous thread was unfalsifiable for a while.
    try_form = probe("def run do\n    :ok\n  rescue\n    _ -> :ok\n  end")
    body_form = probe("def run do\n    try do\n      :ok\n    after\n      :ok\n    end\n  end")

    found = {swallowing_forms(try_form), swallowing_forms(body_form)}

    File.rm!(try_form)
    File.rm!(body_form)

    assert {[:rescue], [:after]} = found
  end

  test "failure: an exception in predicate evaluation propagates out of the run" do
    assert_raise RuntimeError, "predicate raised on n=1", fn ->
      Sia.run(Ctx.new(run_id: "no-rescue"), SiaFixtures.raising_pipeline(), [%{"n" => "1"}])
    end
  end

  defp swallowing_forms(path) do
    {_ast, found} =
      path
      |> File.read!()
      |> Code.string_to_quoted!()
      |> Macro.prewalk([], &collect_swallow/2)

    Enum.uniq(found)
  end

  # `try do ... rescue ... end` and the implicit form in a function body both
  # carry their handlers as block keywords, so one clause catches both.
  defp collect_swallow({key, _handlers} = node, acc) when key in @swallowing_forms,
    do: {node, [key | acc]}

  defp collect_swallow(node, acc), do: {node, acc}

  defp probe(body) do
    path =
      Path.join(
        System.tmp_dir!(),
        "riffle_no_rescue_probe_#{System.unique_integer([:positive])}.ex"
      )

    File.write!(path, "defmodule Probe do\n  #{body}\nend\n")

    path
  end
end
