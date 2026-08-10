defmodule Riffle.ExtricationGateTest do
  use ExUnit.Case, async: true

  # The needle is assembled at runtime so this file never contains the
  # literal it hunts; the scan therefore covers every file under lib/ and
  # test/ with no exclusions, itself included.
  @needle String.downcase("multi" <> "plyer")

  test "invariant: lib/ and test/ carry zero source-project traces" do
    offending =
      Path.wildcard("{lib,test}/**/*")
      |> Enum.filter(&File.regular?/1)
      |> Enum.filter(fn path ->
        path |> File.read!() |> String.downcase() |> String.contains?(@needle)
      end)

    assert offending == []
  end
end
