defmodule Riffle.Predicate.ResolverTest do
  use ExUnit.Case, async: true

  alias Riffle.Predicate.Item
  alias Riffle.Predicate.Loop
  alias Riffle.Predicate.Pipeline
  alias Riffle.Predicate.Resolver
  alias Riffle.Predicate.UnresolvedPredicateError

  defmodule Definitions do
    def get_predicate(:active) do
      %{
        name: :active,
        description: "active users",
        function: fn item -> item.fields["status"] == "active" end
      }
    end

    def get_predicate(:aliased), do: %{name: :active, inline: false}
    def get_predicate(:cycle_a), do: %{name: :cycle_b, inline: false}
    def get_predicate(:cycle_b), do: %{name: :cycle_a, inline: false}
    def get_predicate(:broken), do: %{name: :broken, function: :not_a_function}
    def get_predicate(_name), do: nil

    def get_loop(:active_loop) do
      %{
        name: :active_loop,
        description: "loop of one reference",
        predicates: [%{name: :active, inline: false}]
      }
    end

    def get_loop(:aliased_loop), do: %{name: :active_loop, inline: false}
    def get_loop(:loop_cycle), do: %{name: :loop_cycle, inline: false}

    def get_loop(:broken_loop),
      do: %{name: :broken_loop, predicates: [%{name: :missing, inline: false}]}

    def get_loop(_name), do: nil

    def get_pipeline(:flow) do
      %{
        name: :flow,
        description: "one-loop pipeline",
        loops: [%{name: :active_loop, inline: false}]
      }
    end

    def get_pipeline(_name), do: nil
  end

  defp active_item, do: Item.new(["status"], ["active"])
  defp inactive_item, do: Item.new(["status"], ["inactive"])

  describe "resolve_predicate/2 with a module source" do
    test "success: resolves a reference to a runnable definition" do
      ref = %{name: :active, inline: false}

      assert {:ok, %{name: :active, function: function}} =
               Resolver.resolve_predicate(Definitions, ref)

      assert function.(active_item()) == true
      assert function.(inactive_item()) == false
    end

    test "success: follows a reference chain to the terminal definition" do
      ref = %{name: :aliased, inline: false}

      assert {:ok, %{name: :active, function: function}} =
               Resolver.resolve_predicate(Definitions, ref)

      assert function.(active_item()) == true
    end

    test "success: hydrates an inline body into a function exactly once" do
      ref = %{
        name: :adult,
        description: "age gate",
        body: quote(do: fn item -> item.fields["age"] == "21" end)
      }

      assert {:ok, %{name: :adult, description: "age gate", function: function}} =
               Resolver.resolve_predicate(Definitions, ref)

      assert function.(Item.new(["age"], ["21"])) == true
      assert function.(Item.new(["age"], ["7"])) == false
    end

    test "success: passes an already-runnable definition through unchanged" do
      definition = %{name: :ready, description: "", function: fn _item -> true end}

      assert {:ok, ^definition} = Resolver.resolve_predicate(Definitions, definition)
    end

    test "failure: an unknown name is a tagged unresolved error naming the module" do
      ref = %{name: :missing, inline: false}

      assert Resolver.resolve_predicate(Definitions, ref) ==
               {:error, {:unresolved, :predicate, :missing, Definitions}}
    end

    test "failure: a reference cycle is detected and reported with its path" do
      ref = %{name: :cycle_a, inline: false}

      assert Resolver.resolve_predicate(Definitions, ref) ==
               {:error, {:cycle, :predicate, [:cycle_a, :cycle_b, :cycle_a]}}
    end

    test "failure: an unrecognised ref shape is a tagged invalid_ref error" do
      ref = %{unexpected: :shape}

      assert Resolver.resolve_predicate(Definitions, ref) ==
               {:error, {:invalid_ref, :predicate, %{unexpected: :shape}}}
    end

    test "failure: a definition whose function is not arity-1 is invalid, never re-hydrated" do
      ref = %{name: :broken, inline: false}

      assert Resolver.resolve_predicate(Definitions, ref) ==
               {:error, {:invalid_ref, :predicate, %{name: :broken, function: :not_a_function}}}
    end
  end

  describe "resolve_predicate/2 with a definitions-map source" do
    test "success: resolves a reference against the map" do
      definition = %{name: :active, description: "", function: fn _item -> true end}

      defs = %{predicates: %{active: definition}, loops: %{}, pipelines: %{}}

      assert {:ok, ^definition} =
               Resolver.resolve_predicate(defs, %{name: :active, inline: false})
    end

    test "failure: a name absent from the map is unresolved with the :definitions descriptor" do
      defs = %{predicates: %{}, loops: %{}, pipelines: %{}}

      assert Resolver.resolve_predicate(defs, %{name: :missing, inline: false}) ==
               {:error, {:unresolved, :predicate, :missing, :definitions}}
    end
  end

  describe "resolve_loop/2" do
    test "success: hydrates a loop reference recursively into a runnable Loop" do
      ref = %{name: :active_loop, inline: false}

      assert {:ok, %Loop{name: :active_loop, predicates: [%{name: :active}]} = loop} =
               Resolver.resolve_loop(Definitions, ref)

      assert {true, %Item{tags: [:active]}} = Loop.process(loop, active_item())
      assert {false, %Item{tags: []}} = Loop.process(loop, inactive_item())
    end

    test "success: follows a loop reference chain to the terminal definition" do
      ref = %{name: :aliased_loop, inline: false}

      assert {:ok, %Loop{name: :active_loop}} = Resolver.resolve_loop(Definitions, ref)
    end

    test "success: re-walks a Loop struct so unresolved innards cannot leak through" do
      struct_with_refs = %Loop{
        name: :handmade,
        description: "",
        predicates: [%{name: :active, inline: false}]
      }

      assert {:ok, %Loop{name: :handmade, predicates: [%{name: :active, function: function}]}} =
               Resolver.resolve_loop(Definitions, struct_with_refs)

      assert function.(active_item()) == true
    end

    test "failure: a loop self-cycle is detected" do
      ref = %{name: :loop_cycle, inline: false}

      assert Resolver.resolve_loop(Definitions, ref) ==
               {:error, {:cycle, :loop, [:loop_cycle, :loop_cycle]}}
    end

    test "failure: an unresolvable predicate inside a loop propagates its own error" do
      ref = %{name: :broken_loop, inline: false}

      assert Resolver.resolve_loop(Definitions, ref) ==
               {:error, {:unresolved, :predicate, :missing, Definitions}}
    end
  end

  describe "resolve_pipeline/2" do
    test "success: resolves the full pipeline recursively and it filters end to end" do
      ref = %{name: :flow, inline: false}

      assert {:ok, %Pipeline{name: :flow, loops: [%Loop{name: :active_loop}]} = pipeline} =
               Resolver.resolve_pipeline(Definitions, ref)

      results = pipeline |> Pipeline.process([active_item(), inactive_item()]) |> Enum.to_list()

      assert [%Item{tags: [:active], fields: %{"status" => "active"}}] = results
    end

    test "success: accepts an already-hydrated Pipeline struct and re-walks it" do
      {:ok, pipeline} = Resolver.resolve_pipeline(Definitions, %{name: :flow, inline: false})

      assert {:ok, %Pipeline{name: :flow, loops: [%Loop{}]}} =
               Resolver.resolve_pipeline(Definitions, pipeline)
    end

    test "failure: an unrecognised pipeline shape is a tagged invalid_ref error" do
      assert Resolver.resolve_pipeline(Definitions, :not_a_pipeline) ==
               {:error, {:invalid_ref, :pipeline, :not_a_pipeline}}
    end
  end

  describe "bang variants" do
    test "success: resolve_predicate! returns the runnable definition" do
      assert %{name: :active, function: function} =
               Resolver.resolve_predicate!(Definitions, %{name: :active, inline: false})

      assert function.(active_item()) == true
    end

    test "failure: an unresolved reference raises naming the module and the predicate" do
      assert_raise UnresolvedPredicateError, ~r/Definitions has no such predicate/, fn ->
        Resolver.resolve_predicate!(Definitions, %{name: :missing, inline: false})
      end
    end

    test "failure: an invalid ref raises naming the offending shape" do
      assert_raise UnresolvedPredicateError, ~r/invalid predicate reference/, fn ->
        Resolver.resolve_predicate!(Definitions, %{unexpected: :shape})
      end
    end

    test "failure: a cycle raises naming the reference path" do
      assert_raise UnresolvedPredicateError, ~r/circular predicate reference/, fn ->
        Resolver.resolve_predicate!(Definitions, %{name: :cycle_a, inline: false})
      end
    end

    test "failure: resolve_loop! raises for an unresolvable loop" do
      assert_raise UnresolvedPredicateError, ~r/Definitions has no such loop/, fn ->
        Resolver.resolve_loop!(Definitions, %{name: :missing_loop, inline: false})
      end
    end
  end
end
