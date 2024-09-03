defmodule Essig.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Essig.Repo,
      Essig.RepoSingleConn,
      {Phoenix.PubSub, name: Essig.PubSub},
      {Registry, keys: :unique, name: Essig.Scopes.Registry},
      Essig.Scopes.DynamicSupervisor
    ]

    opts = [strategy: :one_for_one, name: Essig.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
