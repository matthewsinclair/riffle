defmodule Riffle.Cli.MixTaskTest do
  use ExUnit.Case, async: true

  alias Riffle.FenceHelpers

  # DD-4: exactly one argv parser exists in this project.
  #
  # hv's instruction was that the CLI and the mix task are both thin
  # coordinators over the service module. Read literally that would put a
  # second doorway into `Riffle.Service` -- and a second doorway needs its own
  # argument parsing, which is two parsers for one command surface and the
  # Highlander violation in its most familiar form. The two would drift: a flag
  # added to one, a default changed in the other, and `mix riffle.cli sia.run`
  # would quietly stop meaning what `riffle sia.run` means.
  #
  # So mix is a doorway and the framework is the parser. The mechanical
  # statement of that is this: the task names the framework and no Riffle
  # module whatsoever -- not the service, not the commands. If it ever reaches
  # into Riffle directly, it has started doing work, and this goes red.

  @task_source "lib/mix/tasks/riffle.cli.ex"

  test "fence: the mix task names no Riffle module at all" do
    named = FenceHelpers.named_modules(@task_source)

    assert named != []
    assert Enum.filter(named, &String.starts_with?(&1, FenceHelpers.root_namespace())) == []
  end

  test "fence: the mix task does name the CLI framework, so it is a doorway and not a stub" do
    named = FenceHelpers.named_modules(@task_source)

    assert Enum.any?(named, &String.starts_with?(&1, FenceHelpers.cli_framework_namespace()))
  end

  test "invariant: the task is where the devbin launcher looks for it" do
    # `bin/riffle cli` shells to `mix <project>.cli`, so the task's name is not
    # a free choice -- it is what the launcher resolves. Before this existed the
    # launcher reported "the task riffle.cli could not be found", which reads as
    # a broken launcher rather than a missing feature.
    assert File.exists?(@task_source)
    assert Mix.Task.get("riffle.cli") == Mix.Tasks.Riffle.Cli
  end
end
