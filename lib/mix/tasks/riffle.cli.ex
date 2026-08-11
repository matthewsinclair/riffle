defmodule Mix.Tasks.Riffle.Cli do
  @moduledoc """
  Runs the Riffle CLI: `mix riffle.cli [command] [args]`.

  This is what `bin/riffle cli` resolves to, and it is a doorway and nothing
  more. It hands argv to the CLI framework and returns.

  It does **not** call `Riffle.Service` directly. Reading "the mix task is a
  thin coordinator over the service module" literally would put a second
  doorway into the service, and a second doorway needs its own argument
  parsing -- two parsers for one command surface, which is the Highlander
  violation in its most familiar form. Mix stays a doorway; the framework
  stays the only parser. `test/riffle/cli/mix_task_test.exs` holds it to that.
  """

  use Mix.Task

  @shortdoc "Runs the Riffle CLI"

  @requirements ["app.config", "app.start"]

  @impl Mix.Task
  def run(args) do
    _ = Arca.Cli.main(args)

    # Returning nothing keeps Mix from printing the framework's return value
    # underneath the output the command already rendered.
    nil
  end
end
