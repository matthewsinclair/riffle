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

  alias Riffle.Predicate.Dsl.Evaluator
  alias Riffle.Predicate.Dsl.Loader
  alias Riffle.Predicate.Item

  @standard_lib Riffle.Predicate.StandardLib

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

  @doc """
  The bodies of every fenced code block in a markdown file carrying `language`.

  The reference doc marks complete `.pred` definitions as `pred` and bare
  expressions as `expr`, so each kind can be checked by the thing that really
  reads it rather than by eye.
  """
  @spec code_blocks(Path.t(), String.t()) :: [String.t()]
  def code_blocks(path, language) do
    {:ok, fence} = Regex.compile("^```#{language}\n(.*?)^```", "ms")

    fence
    |> Regex.scan(File.read!(path))
    |> Enum.map(fn [_whole, body] -> body end)
  end

  @doc "Every non-blank line of every `expr` block in a markdown file, one expression each."
  @spec expressions(Path.t()) :: [String.t()]
  def expressions(path) do
    path
    |> code_blocks("expr")
    |> Enum.flat_map(&String.split(&1, "\n"))
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  @doc """
  Runs a documented expression against an item.

  `:ok` when the evaluator accepts the form, `{:raised, message}` when it does
  not. Only `ArgumentError` is caught, which is what an unsupported form
  raises; anything else is a defect in the evaluator and propagates.
  """
  @spec evaluation(String.t(), Item.t()) :: :ok | {:raised, String.t()}
  def evaluation(expression, %Item{} = item) do
    {:ok, match?} = Evaluator.parse(expression)
    match?.(item)
    :ok
  rescue
    error in ArgumentError -> {:raised, Exception.message(error)}
  end

  @doc """
  Loads a documented `.pred` snippet the way a `.pred` file is loaded.

  `:ok` when the snippet parses, extracts and materialises -- so a snippet
  whose references do not resolve fails here rather than misleading a reader.
  """
  @spec pred_load(String.t()) :: :ok | {:error, term()}
  def pred_load(snippet) do
    with {:ok, definitions} <- Loader.load_string(snippet),
         {:ok, _instances} <- Loader.create_instances(definitions) do
      :ok
    end
  end

  @doc """
  Every link in a markdown file that points at something in this repository.

  Markdown link targets and `src` attributes, minus absolute URLs and
  fragments -- what is left is a promise about a path, which is a promise a
  machine can keep.
  """
  @spec local_links(Path.t()) :: [String.t()]
  def local_links(path) do
    text = File.read!(path)
    links = targets(text, ~r/\[[^\]]*\]\(([^)\s]+)\)/)
    images = targets(text, ~r/\bsrc="([^"]+)"/)

    (links ++ images) |> Enum.reject(&elsewhere?/1) |> Enum.uniq()
  end

  @doc "Every public builder in the standard library, as `{module, name, arity}`."
  @spec standard_lib_predicates() :: [{module(), atom(), arity()}]
  def standard_lib_predicates do
    for module <- modules(),
        standard_lib?(module),
        {name, arity} <- module.__info__(:functions),
        do: {module, name, arity}
  end

  @doc """
  How a standard-library builder is written inside a `.pred` file.

  `STD` is the name bound where bodies evaluate, so `STD.Text.equals/2` is the
  reference a reader can act on -- and the token the coverage fence looks for.
  """
  @spec standard_lib_reference({module(), atom(), arity()}) :: String.t()
  def standard_lib_reference({module, name, arity}) do
    "#{std_alias(module)}.#{name}/#{arity}"
  end

  defp targets(text, pattern) do
    pattern |> Regex.scan(text) |> Enum.map(&Enum.at(&1, 1))
  end

  defp elsewhere?(target), do: target =~ ~r{^([a-z]+:)?//|^#|^mailto:}

  defp standard_lib?(module) do
    module |> inspect() |> String.starts_with?(inspect(@standard_lib))
  end

  defp std_alias(module) do
    module |> inspect() |> String.replace_prefix(inspect(@standard_lib), "STD")
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
