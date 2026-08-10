defmodule Riffle.ConfigHelpers do
  @moduledoc """
  THE one home for `:riffle` application-environment preconditions in tests
  (test-highlander).

  Three suites need the default-pipeline module set for the length of a test
  and put back afterwards. Each had grown its own save-and-restore block, and
  each carried the same `case` on the two shapes `Application.fetch_env/2`
  returns -- control flow in a setup, written out three times. It lives here
  once, and the branch is a multi-clause private function rather than a `case`.

  Restoration registers with `on_exit/1` at the moment the value is set, so a
  test that changes nothing needs no teardown, and a suite cannot leak a
  configured module into the one that follows it.
  """

  import ExUnit.Callbacks, only: [on_exit: 1]

  @key :default_pipeline

  @doc "Sets the default-pipeline module for this test, restoring the previous value afterwards."
  @spec put_default_pipeline(module()) :: :ok
  def put_default_pipeline(module) when is_atom(module) do
    restore_after()

    Application.put_env(:riffle, @key, module)
  end

  @doc "Unsets the default-pipeline module for this test, restoring the previous value afterwards."
  @spec delete_default_pipeline() :: :ok
  def delete_default_pipeline do
    restore_after()

    Application.delete_env(:riffle, @key)
  end

  defp restore_after do
    original = Application.fetch_env(:riffle, @key)

    on_exit(fn -> restore(original) end)
  end

  defp restore({:ok, value}), do: Application.put_env(:riffle, @key, value)
  defp restore(:error), do: Application.delete_env(:riffle, @key)
end
