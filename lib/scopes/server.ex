defmodule Essig.Scopes.Server do
  use Supervisor

  def start_link(scope) do
    Supervisor.start_link(__MODULE__, [], name: via_tuple(scope))
  end

  def via_tuple(scope) do
    {:via, Registry, {Scopes.Registry, scope}}
  end

  @impl true
  def init(_init_arg) do
    # start 2 registries, that respect the current scope
    children = [
      Essig.Casts.Registry,
      Essig.Entities.Registry
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
