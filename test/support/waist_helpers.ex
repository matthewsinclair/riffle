defmodule Riffle.WaistHelpers do
  @moduledoc """
  One home for the waist's identity and the introspection the fences share.

  The namespace, the source paths, and the typespec walk were transcribed into
  four fence files in three different encodings. A rename then touched four
  files, and a partial update failed differently in each. They live here once.

  The namespaces are assembled at runtime so this file never contains the
  literal a source-scanning fence hunts for.
  """

  @waist "Riffle." <> "Ctx"
  @engine "Riffle." <> "Predicate"

  @doc "The waist's module namespace."
  def waist_namespace, do: @waist

  @doc "The engine's module namespace."
  def engine_namespace, do: @engine

  @doc "Every source file in the waist."
  def waist_sources, do: Path.wildcard("lib/riffle/ctx/**/*.ex")

  @doc "Every source file in the engine."
  def engine_sources, do: Path.wildcard("lib/riffle/predicate/**/*.ex")

  @doc "Whether a module belongs to the waist."
  def waist_module?(module), do: prefixed?(module, [@waist])

  @doc "Whether a module belongs to Riffle at all."
  def riffle_module?(module), do: prefixed?(module, ["Riffle"])

  @doc "Whether a module is one of the waist's typed I/O types."
  def catalog_module?(module),
    do: prefixed?(module, [@waist <> ".Perturbation", @waist <> ".Emission"])

  defp prefixed?(module, namespaces),
    do: String.starts_with?(Atom.to_string(module), Enum.map(namespaces, &("Elixir." <> &1)))

  @doc """
  The source directory holding a catalog's struct modules.

  Derived from the catalog's own name rather than transcribed, so it cannot
  drift from the module it describes.
  """
  def catalog_dir(catalog), do: "lib/" <> Macro.underscore(catalog)

  @doc "The module a catalog source file defines."
  def catalog_module(catalog, path),
    do: Module.concat(catalog, path |> Path.basename(".ex") |> Macro.camelize())

  @doc "Whether a module defines a struct. Loads it first -- function_exported?/3 lies about unloaded modules."
  def struct_module?(module) do
    Code.ensure_loaded!(module)
    function_exported?(module, :__struct__, 0)
  end

  @doc "Whether a module exports a function. Loads it first, for the same reason."
  def exports?(module, function, arity) do
    Code.ensure_loaded!(module)
    function_exported?(module, function, arity)
  end

  @doc """
  Every module a source file names, read from its parsed AST.

  Text scanning is not adequate here: `alias Riffle.{Ctx, Foo}` never produces
  the substring `Riffle.Ctx`, and that brace form is already idiomatic in this
  codebase. Walking the AST also stops moduledoc prose from reading as a
  dependency, which a text scan cannot distinguish.
  """
  def named_modules(path) do
    {_ast, names} =
      path
      |> File.read!()
      |> Code.string_to_quoted!()
      |> Macro.prewalk([], &collect_alias/2)

    Enum.uniq(names)
  end

  # alias Prefix.{A, B} -- the inner aliases are relative to the prefix
  defp collect_alias({{:., _, [{:__aliases__, _, prefix}, :{}]}, _, nested} = node, acc) do
    {node,
     Enum.map(nested, fn {:__aliases__, _, segments} -> dotted(prefix ++ segments) end) ++ acc}
  end

  defp collect_alias({:__aliases__, _, segments} = node, acc) when is_list(segments) do
    {node, [dotted(segments) | acc]}
  end

  defp collect_alias(node, acc), do: {node, acc}

  defp dotted(segments), do: segments |> Enum.filter(&is_atom/1) |> Enum.join(".")

  @doc """
  The declared field types of a struct module's `t()`, read from the typespec.

  Reading the spec rather than a built value is the point: a slot typed `map()`
  cannot hide behind a well-behaved default.
  """
  def field_types!(module) do
    {:type, {:t, {:type, _line, :map, fields}, []}} = fetch_type!(module, :t)

    fields
    |> Map.new(fn {:type, _, :map_field_exact, [{:atom, _, field}, type]} -> {field, type} end)
    |> Map.delete(:__struct__)
  end

  @doc "Fetches one named type from a module's typespec, raising if it is absent."
  def fetch_type!(module, name) do
    module
    |> Code.Typespec.fetch_types()
    |> types!(module)
    |> Enum.find(fn
      {:type, {^name, _definition, []}} -> true
      _other -> false
    end) || raise ArgumentError, "#{inspect(module)} declares no type #{name}/0"
  end

  defp types!({:ok, types}, _module), do: types

  defp types!(:error, module),
    do: raise(ArgumentError, "#{inspect(module)} has no typespec chunk -- is it compiled?")

  @doc """
  Every module named by a type expression, walked out of the Erlang type AST.

  The remote-type form carries three list elements (module, function, args), not
  two. Matching two silently returns nothing for every remote type, which is how
  a fence built on this goes quietly dead.
  """
  def remote_modules({:remote_type, _, [{:atom, _, module}, {:atom, _, _function}, args]}),
    do: [module | Enum.flat_map(args, &remote_modules/1)]

  def remote_modules({:type, _, _kind, args}) when is_list(args),
    do: Enum.flat_map(args, &remote_modules/1)

  def remote_modules({:ann_type, _, args}) when is_list(args),
    do: Enum.flat_map(args, &remote_modules/1)

  def remote_modules({:user_type, _, _name, args}) when is_list(args),
    do: Enum.flat_map(args, &remote_modules/1)

  def remote_modules(_type), do: []
end
