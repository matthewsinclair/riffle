defmodule Riffle.Application do
  @moduledoc """
  The OTP application: it supervises `Riffle.Predicate.Cache` and nothing else.

  Documented rather than hidden because a reader needs the fact it carries.
  Starting `:riffle` starts the evaluation cache, so a caller never starts one
  and `Riffle.Predicate.Cache.start_link/1` on a live system answers
  `{:error, {:already_started, pid}}`. Every other module in the tree is a
  plain module a caller may use without any of this being running.

  One child, restarted on its own (`:one_for_one`), because the cache is a
  performance store rather than a source of truth: losing it costs
  re-evaluation, not correctness.
  """

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
