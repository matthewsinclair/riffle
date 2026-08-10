defmodule Riffle.Ctx.Emission.Kind do
  @moduledoc """
  The contract every emission type implements.

  It lives beside the catalog rather than inside `Riffle.Ctx.Emission` so the
  registry can call `tag/0` on its implementations at compile time without the
  implementations depending back on the registry.
  """

  @doc "The tag identifying this emission. Unique within the catalog."
  @callback tag() :: atom()
end
