defmodule Riffle.Predicate.PipelineConfig do
  @moduledoc """
  Behaviour defining interface for pipeline configuration modules.

  This behaviour ensures that pipeline configuration modules provide
  consistent interfaces for accessing pipeline definitions, loops, and predicates.
  It establishes a compile-time contract that enables reliable function discovery
  and promotes a more robust architecture.
  """

  @doc """
  Returns a pipeline definition by name or nil if not found.

  ## Parameters
    * `name` - Name of the pipeline as atom or string
    
  ## Returns
    * Pipeline definition map or nil if pipeline not found
  """
  @callback get_pipeline(name :: atom() | String.t()) :: map() | nil

  @doc """
  Returns a loop definition by name or nil if not found.

  ## Parameters
    * `name` - Name of the loop
    
  ## Returns
    * Loop definition map or nil if loop not found
  """
  @callback get_loop(name :: atom()) :: map() | nil

  @doc """
  Returns a predicate definition by name or nil if not found.

  ## Parameters
    * `name` - Name of the predicate
    
  ## Returns
    * Predicate definition map or nil if predicate not found
  """
  @callback get_predicate(name :: atom()) :: map() | nil

  @doc """
  Returns list of all available pipeline names.

  ## Returns
    * List of pipeline names as atoms
  """
  @callback list_pipelines() :: [atom()]
end
