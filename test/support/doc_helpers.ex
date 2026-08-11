defmodule Riffle.DocHelpers do
  @moduledoc """
  Introspection over the compiled application's documentation.

  Lives in `test/support` rather than beside the fences that use it for the
  reason `mix.exs` already gives: support modules are ordinary Elixir, so they
  may use the `case` and `if` that IN-EX-TEST-005 forbids inside test bodies.
  Walking docs is branchy work, and the branches belong here.

  One home, because two fences already need it -- the doc-conformance fences
  and, in turn, the `.pred` reference checks -- and a second copy of a doc walk
  is a second answer capable of disagreeing with the first.
  """

  @doc "Every module in the compiled application, sorted."
  @spec modules() :: [module()]
  def modules, do: :riffle |> Application.spec(:modules) |> Enum.sort()

  @doc "A module's moduledoc, or `\"\"` when it has none."
  @spec moduledoc(module()) :: String.t()
  def moduledoc(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, doc, _, _} -> text(doc)
      _otherwise -> ""
    end
  end

  @doc """
  How many doctest prompts a module's docs carry, across the moduledoc and every `@doc`.

  A prompt *begins* its line. Matching the token anywhere would count prose
  that merely mentions it -- this module's own docs do, and the fence built on
  this function reported itself before the rule was tightened.
  """
  @spec examples(module()) :: non_neg_integer()
  def examples(module) do
    module
    |> all_docs()
    |> Enum.join("\n")
    |> String.split("\n")
    |> Enum.count(&(&1 |> String.trim_leading() |> String.starts_with?("iex>")))
  end

  @doc "Every module named by a `doctest` declaration anywhere in the suite."
  @spec declared_doctests() :: [String.t()]
  def declared_doctests do
    "test/**/*.exs"
    |> Path.wildcard()
    |> Enum.flat_map(fn file ->
      ~r/^\s*doctest\s+([A-Za-z0-9_.]+)/m
      |> Regex.scan(File.read!(file))
      |> Enum.map(fn [_whole, module] -> module end)
    end)
  end

  @doc "A module's public functions and macros that carry no `@doc`, excluding generated ones."
  @spec undocumented(module()) :: [{atom(), arity()}]
  def undocumented(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, _, _, docs} ->
        for {{kind, name, arity}, _, _, :none, meta} <- docs,
            kind in [:function, :macro],
            is_nil(meta[:behaviour]),
            not generated?(name),
            do: {name, arity}

      _otherwise ->
        []
    end
  end

  @doc "A struct module's fields, sorted, without `:__struct__`."
  @spec struct_fields(module()) :: [atom()]
  def struct_fields(module) do
    module.__struct__() |> Map.keys() |> List.delete(:__struct__) |> Enum.sort()
  end

  @doc """
  Every `fun/arity` reference written in backticks in a module's docs.

  Each is returned as `{source, where, target, function, arity}`, with the
  target resolved against the module the doc came from so an unqualified
  reference is checked where a reader would look for it. References to modules
  outside this project are dropped -- they are not ours to keep true.
  """
  @spec references(module()) :: [{module(), String.t(), module(), String.t(), arity()}]
  def references(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, doc, _, docs} ->
        scan(module, "moduledoc", text(doc)) ++
          Enum.flat_map(docs, fn {{_, name, arity}, _, _, own, _} ->
            scan(module, "#{name}/#{arity}", text(own))
          end)

      _otherwise ->
        []
    end
  end

  @doc "Whether a reference from `references/1` points at something that exists."
  @spec resolves?({module(), String.t(), module(), String.t(), arity()}) :: boolean()
  def resolves?({_source, _where, target, function, arity}) do
    name = String.to_atom(function)

    Code.ensure_loaded?(target) and
      Enum.any?(exports(target), &(&1 == {name, arity}))
  end

  defp exports(module) do
    module.__info__(:functions) ++ module.__info__(:macros) ++ callbacks(module)
  end

  defp callbacks(module) do
    case Code.Typespec.fetch_callbacks(module) do
      {:ok, found} -> Enum.map(found, fn {{name, arity}, _} -> {name, arity} end)
      :error -> []
    end
  end

  defp scan(module, where, doc) do
    ~r/`c?:?([A-Za-z_][A-Za-z0-9_.]*)\/(\d+)`/
    |> Regex.scan(doc)
    |> Enum.map(fn [_whole, dotted, arity] ->
      {target, function} = split(module, dotted)
      {module, where, target, function, String.to_integer(arity)}
    end)
    |> Enum.filter(fn {_, _, target, _, _} -> ours?(target) end)
    |> Enum.uniq()
  end

  defp split(module, dotted) do
    case String.split(dotted, ".") do
      [function] -> {module, function}
      parts -> {Module.concat(Enum.drop(parts, -1)), List.last(parts)}
    end
  end

  defp ours?(module), do: module |> Atom.to_string() |> String.starts_with?("Elixir.Riffle")

  defp generated?(name), do: name |> Atom.to_string() |> String.starts_with?("__")

  defp all_docs(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, doc, _, docs} ->
        [text(doc) | Enum.map(docs, fn {_, _, _, own, _} -> text(own) end)]

      _otherwise ->
        []
    end
  end

  defp text(%{"en" => doc}), do: doc
  defp text(_otherwise), do: ""
end
