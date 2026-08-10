defmodule Riffle.ExtricationGateTest do
  use ExUnit.Case, async: true

  # The needle is assembled at runtime so this file never contains the
  # literal it hunts; the scan therefore covers every file under lib/ and
  # test/ with no exclusions, itself included.
  @needle String.downcase("multi" <> "plyer")

  test "invariant: lib/ and test/ carry zero source-project traces" do
    offending =
      Enum.filter(Path.wildcard("{lib,test}/**/*"), fn path ->
        File.regular?(path) and
          path |> File.read!() |> String.downcase() |> String.contains?(@needle)
      end)

    assert offending == []
  end
end
