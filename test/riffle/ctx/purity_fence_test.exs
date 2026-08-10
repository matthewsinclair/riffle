defmodule Riffle.Ctx.PurityFenceTest do
  use ExUnit.Case, async: true

  alias Riffle.Ctx.Knot
  alias Riffle.FenceHelpers

  # AC-02.1. Approximate purity is a failure, not a tolerance -- so this fence
  # reads compiled call targets rather than source text, and walks the whole
  # closure reachable from the knot rather than checking the knot alone. One
  # logger call three modules deep is exactly what a source grep would miss.
  #
  # The closure recurses through Riffle modules and stops at the standard
  # library: Enum and Map are trusted, but a *call* to Logger, File, :ets or a
  # clock is a finding wherever it appears.

  @forbidden_modules [
    Logger,
    IO,
    File,
    System,
    Code,
    DateTime,
    NaiveDateTime,
    Date,
    Time,
    Process,
    Task,
    GenServer,
    Agent,
    :file,
    :rand,
    :random,
    :ets,
    :dets,
    :os,
    :timer,
    :persistent_term,
    :crypto,
    :global
  ]

  @forbidden_erlang_functions [
    :now,
    :timestamp,
    :monotonic_time,
    :system_time,
    :unique_integer,
    :make_ref,
    :self,
    :spawn,
    :spawn_link,
    :spawn_monitor,
    :send,
    :whereis,
    :put,
    :get,
    :erase,
    :process_info,
    :date,
    :time,
    :universaltime,
    :localtime
  ]

  test "fence: no module reachable from the knot touches a clock, random, process, table, file, or logger" do
    calls = call_closure(Knot)

    assert calls != []

    offending = Enum.filter(calls, &forbidden?/1)

    assert offending == []
  end

  test "fence: the closure reachable from the knot stays inside the waist" do
    calls = call_closure(Knot)

    assert calls != []

    leaked =
      calls
      |> Enum.map(fn {module, _function, _arity} -> module end)
      |> Enum.filter(&(FenceHelpers.riffle_module?(&1) and not FenceHelpers.waist_module?(&1)))
      |> Enum.uniq()

    assert leaked == []
  end

  # -- the call closure -------------------------------------------------------

  defp call_closure(module), do: expand([module], MapSet.new(), [])

  defp expand([], _visited, calls), do: calls

  defp expand([module | rest], visited, calls),
    do: visit(MapSet.member?(visited, module), module, rest, visited, calls)

  defp visit(true, _module, rest, visited, calls), do: expand(rest, visited, calls)

  defp visit(false, module, rest, visited, calls) do
    mfas = module_calls(module)

    next =
      for {called, _function, _arity} <- mfas, FenceHelpers.riffle_module?(called), do: called

    expand(rest ++ next, MapSet.put(visited, module), calls ++ mfas)
  end

  defp module_calls(module) do
    Code.ensure_loaded!(module)

    {:beam_file, ^module, _exports, _attributes, _compile_info, code} =
      module |> :code.which() |> :beam_disasm.file()

    code |> mfas() |> Enum.uniq()
  end

  defp mfas({:extfunc, module, function, arity}), do: [{module, function, arity}]
  defp mfas({:bif, name, _fail, args, _dest}), do: [{:erlang, name, length(args)}]
  defp mfas({:gc_bif, name, _fail, _live, args, _dest}), do: [{:erlang, name, length(args)}]
  defp mfas(term) when is_tuple(term), do: term |> Tuple.to_list() |> Enum.flat_map(&mfas/1)
  defp mfas(list) when is_list(list), do: Enum.flat_map(list, &mfas/1)
  defp mfas(_term), do: []

  defp forbidden?({:erlang, function, _arity}), do: function in @forbidden_erlang_functions
  defp forbidden?({module, _function, _arity}), do: module in @forbidden_modules
end
