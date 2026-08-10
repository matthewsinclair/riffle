defmodule Riffle.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Riffle.Predicate.Cache, []}
    ]

    opts = [strategy: :one_for_one, name: Riffle.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
