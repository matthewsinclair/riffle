defmodule Riffle.Sia.Pipelines do
  @moduledoc """
  THE pipeline source vocabulary for the pattern layer.

  Four shapes, and nothing else:

    * `%Riffle.Predicate.Pipeline{}` -- already built, used as it stands
    * `{:module, module}` -- a `Riffle.Predicate.PipelineConfig` module
    * `{:file, path}` -- a `.pred` file, loaded and hydrated
    * `:default_module` -- whatever `config :riffle, :default_pipeline` names

  Nothing is reimplemented here. Loading is the loader's job, hydration the
  resolver's, and this module chooses between them.

  ## Two kinds of failure, deliberately different

  A source that cannot produce the pipeline asked for -- a missing file, a
  name no module defines, an unconfigured default -- is a **tagged error**.
  Those come from paths and names, which a correct program can get wrong at
  runtime, so `Riffle.Sia` turns them into a failed run: a typed signal a
  caller can read, never a silent empty result.

  A source outside the vocabulary **raises**. No correct program produces one,
  and the honest response to a shape nobody declared is to say so loudly
  rather than to guess.
  """

  alias Riffle.Predicate
  alias Riffle.Predicate.Dsl.Loader
  alias Riffle.Predicate.Pipeline

  @type source :: Pipeline.t() | {:module, module()} | {:file, Path.t()} | :default_module

  @type reason ::
          {:pipeline_not_found, atom(), term()}
          | :no_default_pipeline_module
          | term()

  @default_name :main

  @doc "The pipeline a named source resolves to when the caller names none."
  @spec default_name() :: atom()
  def default_name, do: @default_name

  @doc """
  Fetches the named pipeline from `source`.

  `name` may be `nil`, meaning "whichever this source considers its default":
  for a struct that is the struct itself, and for the named sources it is
  `#{inspect(@default_name)}`.
  """
  @spec fetch(source(), atom() | nil) :: {:ok, Pipeline.t()} | {:error, reason()}
  def fetch(%Pipeline{} = pipeline, nil), do: {:ok, pipeline}
  def fetch(%Pipeline{name: name} = pipeline, name), do: {:ok, pipeline}

  # A struct source carries its own identity, so asking it for a different
  # pipeline is a contradiction in the arguments rather than a lookup that
  # failed. Answering with the struct anyway would silently ignore the name.
  def fetch(%Pipeline{name: actual}, requested) do
    raise ArgumentError,
          "asked for pipeline #{inspect(requested)}, but the source is the " <>
            "pipeline #{inspect(actual)} itself"
  end

  def fetch({:module, module}, name), do: from_module(module, name || @default_name)

  def fetch({:file, path}, name) do
    with {:ok, definitions} <- Loader.load_file(path),
         {:ok, instances} <- Loader.create_instances(definitions) do
      from_instances(instances.pipelines, name || @default_name, {:file, path})
    end
  end

  def fetch(:default_module, name) do
    from_configured(Predicate.default_pipeline(), name || @default_name)
  end

  def fetch(other, _name) do
    raise ArgumentError,
          "#{inspect(other)} is not a pipeline source -- a source is a " <>
            "#{inspect(Pipeline)} struct, {:module, module}, {:file, path}, or :default_module"
  end

  defp from_configured(nil, _name), do: {:error, :no_default_pipeline_module}
  defp from_configured(module, name), do: from_module(module, name)

  defp from_module(module, name) do
    case module.get_pipeline(name) do
      %Pipeline{} = pipeline -> {:ok, pipeline}
      nil -> {:error, {:pipeline_not_found, name, module}}
    end
  end

  defp from_instances(pipelines, name, source) do
    case Map.fetch(pipelines, name) do
      {:ok, %Pipeline{} = pipeline} -> {:ok, pipeline}
      :error -> {:error, {:pipeline_not_found, name, source}}
    end
  end
end
