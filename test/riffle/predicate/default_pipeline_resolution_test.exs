defmodule Riffle.Predicate.DefaultPipelineResolutionTest do
  # Mutates the :riffle application environment -- cannot run async.
  use ExUnit.Case, async: false

  alias Riffle.Predicate.Item
  alias Riffle.Predicate.Loop
  alias Riffle.Predicate.UnresolvedPredicateError

  defmodule ConfiguredPipeline do
    def get_predicate(:always_true) do
      %{name: :always_true, description: "matches every item", function: fn _item -> true end}
    end

    def get_predicate(_name), do: nil
  end

  @moduleless_loop %{
    name: :resolution_loop,
    description: "loop holding a bare predicate reference",
    predicates: [%{name: :always_true, inline: false}]
  }

  setup do
    original = Application.fetch_env(:riffle, :default_pipeline)

    on_exit(fn ->
      case original do
        {:ok, value} -> Application.put_env(:riffle, :default_pipeline, value)
        :error -> Application.delete_env(:riffle, :default_pipeline)
      end
    end)

    :ok
  end

  test "success: configured module resolves a moduleless predicate reference" do
    Application.put_env(:riffle, :default_pipeline, ConfiguredPipeline)

    items = [Item.new(["n"], ["1"])]

    assert [%Item{tags: [:always_true]}] =
             @moduleless_loop |> Loop.filter(items) |> Enum.to_list()
  end

  test "failure: unset config raises naming the missing config key" do
    Application.delete_env(:riffle, :default_pipeline)

    items = [Item.new(["n"], ["1"])]

    assert_raise UnresolvedPredicateError, ~r/config :riffle, :default_pipeline/, fn ->
      @moduleless_loop |> Loop.filter(items) |> Enum.to_list()
    end
  end

  test "failure: configured module without the predicate raises naming the module" do
    Application.put_env(:riffle, :default_pipeline, ConfiguredPipeline)

    loop = %{@moduleless_loop | predicates: [%{name: :no_such_predicate, inline: false}]}
    items = [Item.new(["n"], ["1"])]

    assert_raise UnresolvedPredicateError, ~r/ConfiguredPipeline has no such predicate/, fn ->
      loop |> Loop.filter(items) |> Enum.to_list()
    end
  end

  test "success: default_pipeline/0 returns the configured module, nil when unset" do
    Application.put_env(:riffle, :default_pipeline, ConfiguredPipeline)
    assert Riffle.Predicate.default_pipeline() == ConfiguredPipeline

    Application.delete_env(:riffle, :default_pipeline)
    assert Riffle.Predicate.default_pipeline() == nil
  end

  test "success: resolver falls back to the configured module for a nil source" do
    Application.put_env(:riffle, :default_pipeline, ConfiguredPipeline)

    assert {:ok, %{name: :always_true, function: function}} =
             Riffle.Predicate.Resolver.resolve_predicate(nil, %{name: :always_true, inline: false})

    assert function.(Item.new(["n"], ["1"])) == true
  end

  test "success: a nil source still hydrates an inline body without reading config" do
    Application.delete_env(:riffle, :default_pipeline)

    ref = %{name: :inline_pred, body: quote(do: fn _item -> true end)}

    assert {:ok, %{name: :inline_pred, function: function}} =
             Riffle.Predicate.Resolver.resolve_predicate(nil, ref)

    assert function.(Item.new(["n"], ["1"])) == true
  end

  test "failure: a nil source with no configured default is a tagged no_source error" do
    Application.delete_env(:riffle, :default_pipeline)

    assert Riffle.Predicate.Resolver.resolve_predicate(nil, %{name: :always_true, inline: false}) ==
             {:error, {:no_source, :always_true}}
  end

  test "failure: the no_source bang raise names the missing config key" do
    Application.delete_env(:riffle, :default_pipeline)

    assert_raise UnresolvedPredicateError, ~r/config :riffle, :default_pipeline/, fn ->
      Riffle.Predicate.Resolver.resolve_predicate!(nil, %{name: :always_true, inline: false})
    end
  end
end
