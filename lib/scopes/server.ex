defmodule Essig.Scopes.Server do
  use Supervisor

  def start_link(scope) do
    Supervisor.start_link(__MODULE__, [], name: via_tuple(scope))
  end

  def via_tuple(scope) do
    {:via, Registry, {Essig.Scopes.Registry, scope}}
  end

  @impl true
  def init(_init_arg) do
    # start 2 registries, that respect the current scope
    children = [
      Essig.Projections.Registry,
      Essig.Projections.Supervisor,
      Essig.Entities.Registry
    ]

    # Essig.Casts.MetaTable.init()
    Essig.Projections.MetaTable.init()
    Essig.Entities.MetaTable.init()

    Supervisor.init(children, strategy: :one_for_one)
  end
end
