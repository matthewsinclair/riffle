defmodule Riffle do
  @moduledoc """
  Riffle runs data streams over composable predicate pipelines in three
  tag-driven stages: sense (`signal_*` predicates detect patterns and tag
  items), infer (`inference_*` predicates match signal-tag combinations and
  add insight tags), act (`action_*` predicates fire on inference tags).

  The predicates are the riffles: the stream passes through unimpeded, and
  what matters gets caught.
  """
end
