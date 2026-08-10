defmodule RiffleTest do
  use ExUnit.Case
  doctest Riffle

  test "greets the world" do
    assert Riffle.hello() == :world
  end
end
