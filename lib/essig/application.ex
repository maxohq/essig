defmodule Essig.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Essig.Repo,
      Essig.RepoSingleConn,
      {Phoenix.PubSub, name: Essig.PubSub},
      Essig.PGNotifyListener,
      {Essig.Cache, purge_loop: :timer.seconds(1), default_ttl: :timer.seconds(15)},
      {Registry, keys: :unique, name: Essig.Scopes.Registry},
      Essig.Scopes.DynamicSupervisor
    ]

    # dont log GenCache debug messages by default
    GenCache.Config.log_info()

    opts = [strategy: :one_for_one, name: Essig.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
