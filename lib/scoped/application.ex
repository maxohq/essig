defmodule Scoped.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Scoped.Repo,
      {Registry, keys: :unique, name: Scopes.Registry},
      Scopes.DynamicSupervisor
    ]

    opts = [strategy: :one_for_one, name: Scoped.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
