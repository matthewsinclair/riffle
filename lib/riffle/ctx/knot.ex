defmodule Riffle.Ctx.Knot do
  @moduledoc """
  THE knot: the pure function at the waist of the bowtie.

      tick(ctx, perturbation) -> {ctx', emissions}

  It is the only way a context changes. `Riffle.Ctx` exposes reads and
  construction; every transition happens here, on one typed input, producing the
  new context and the facts about what happened.

  Purity is unconditional, not approximate. Nothing reachable from `tick/2`
  reads a clock, generates a random value, touches a process or a table, opens a
  file, or logs -- which is what makes the same input always produce the same
  output, and a recorded perturbation sequence replay exactly. A diagnostic is
  an emission a consumer realises, never a log line written from in here. The
  fence in `test/riffle/ctx/purity_fence_test.exs` walks the compiled call
  closure and fails the build on any of it.

  `tick/2` takes no consumer, mask, or filter: it emits the full typed stream
  every time. Deciding what to do with an emission is the caller's business, and
  keeping that decision outside means the knot's output is a function of its
  arguments alone.

  Dispatch is multi-clause on the perturbation struct rather than a subscriber
  routing table, because Riffle has no independent subscribers competing for
  tags (ST0002 design.md, DD-4). The cost of that choice is that a new
  perturbation needs a clause here; the delivery floor is what makes forgetting
  one loud rather than silent.
  """

  alias Riffle.Ctx
  alias Riffle.Ctx.Emission
  alias Riffle.Ctx.Perturbation

  @doc """
  Applies one typed perturbation to the context.

  Returns the new context and the emissions describing what happened, in firing
  order. Every perturbation yields at least one emission.
  """
  @spec tick(Ctx.t(), Perturbation.t()) :: {Ctx.t(), [Emission.t()]}
  def tick(%Ctx{} = ctx, perturbation) when is_struct(perturbation) do
    ctx |> transition(perturbation) |> deliver(perturbation)
  end

  # -- transitions ------------------------------------------------------------

  defp transition(ctx, %Perturbation.RunStarted{}), do: change_status(ctx, :running)

  defp transition(ctx, %Perturbation.RunCompleted{output: output}) do
    {completed, emissions} = change_status(%{ctx | output: output}, :completed)

    {completed, emissions ++ [%Emission.OutputProduced{payload: output}]}
  end

  defp transition(ctx, %Perturbation.RunFailed{reason: reason}) do
    {failed, emissions} = ctx |> accumulate_error(reason) |> change_status(:failed)

    {failed, emissions ++ [%Emission.ErrorRaised{error: reason}]}
  end

  defp transition(ctx, %Perturbation.InputReceived{payload: payload}) do
    {%{ctx | input: payload}, [%Emission.InputSet{payload: payload}]}
  end

  defp transition(ctx, %Perturbation.StageEntered{stage: stage}) do
    {ctx, [%Emission.StageStarted{stage: stage}]}
  end

  defp transition(ctx, %Perturbation.StageProgressed{stage: stage, progress: progress}) do
    {ctx, [%Emission.StageProgress{stage: stage, progress: progress}]}
  end

  defp transition(ctx, %Perturbation.StageExited{stage: stage, output: output}) do
    {ctx, [%Emission.StageCompleted{stage: stage, output: output}]}
  end

  defp transition(ctx, %Perturbation.ErrorReported{error: error}) do
    {accumulate_error(ctx, error), [%Emission.ErrorRaised{error: error}]}
  end

  defp transition(ctx, %Perturbation.MetadataRecorded{key: key, value: value}) do
    {%{ctx | metadata: Map.put(ctx.metadata, key, value)},
     [%Emission.MetadataSet{key: key, value: value}]}
  end

  defp transition(ctx, %Perturbation.DiagnosticReported{level: level, message: message}) do
    {ctx, [%Emission.Diagnostic{level: level, message: message}]}
  end

  # A catalog type with no clause above. It does not vanish -- `deliver/2` turns
  # it into a typed default pass, and the delivery-floor fence goes red.
  defp transition(ctx, _perturbation), do: {ctx, :unhandled}

  defp change_status(ctx, status) do
    {%{ctx | status: status}, [%Emission.StatusChanged{from: ctx.status, to: status}]}
  end

  defp accumulate_error(ctx, error), do: %{ctx | errors: ctx.errors ++ [error]}

  # -- the delivery floor -----------------------------------------------------

  # One funnel, no allowlist: a catalog type with no clause above surfaces as a
  # typed fact rather than vanishing.
  #
  # There is deliberately no clause here for a claimed-but-empty result. Every
  # `transition/2` clause returns a non-empty list, and the compiler proves it --
  # a clause for the empty case is reported as unreachable. Adding one anyway
  # would mean silently repairing a future clause that forgot to emit; instead
  # the delivery-floor fence enumerates the catalog and fails the build, so the
  # clause gets fixed rather than papered over.
  defp deliver({ctx, :unhandled}, perturbation), do: {ctx, [default_pass(perturbation)]}

  defp deliver({ctx, emissions}, _perturbation), do: {ctx, emissions}

  # :unhandled is the only reason the floor can report. A clause that claimed a
  # perturbation and emitted nothing cannot reach here -- the compiler proves
  # every transition returns a non-empty list -- so there is no second reason to
  # parameterise for.
  defp default_pass(perturbation) do
    %Emission.DefaultPassed{perturbation_tag: catalog_tag!(perturbation), reason: :unhandled}
  end

  # Loud by construction: a struct that is not a registered perturbation raises
  # here rather than being quietly passed off as one. The edge types its input
  # before the knot ever sees it, so reaching this is a programming error and the
  # message names what arrived.
  defp catalog_tag!(perturbation) do
    module = perturbation.__struct__

    registered!(module, module.tag(), Perturbation.fetch_by_tag(module.tag()))
  end

  defp registered!(module, tag, {:ok, module}), do: tag

  defp registered!(module, tag, _miss) do
    raise ArgumentError,
          "#{inspect(module)} declares tag #{inspect(tag)} but is not registered in " <>
            "Riffle.Ctx.Perturbation -- a struct reaches the knot only through the catalog"
  end
end
