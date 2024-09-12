defmodule Essig.Server do
  import Liveness

  def start_scope(scope) do
    Essig.Context.set_current_scope(scope)
    Essig.Scopes.Server.start_link(scope)
    eventually(&check_registry_is_running/0, 250, 1)
    :ok
  end

  ############ Projections

  def start_projections(modules) do
    Enum.map(modules, fn module ->
      Essig.Projections.Supervisor.start_child(name: module, module: module)
    end)
  end

  def get_projection(module) do
    Essig.Projections.Registry.get(module)
  end

  ############ ENTITIES

  def start_entity(module, uuid) do
    apply(module, :start_link, [[{:uuid, uuid}]])
  end

  def get_entity(module, uuid) do
    Essig.Entities.Registry.get(module, uuid)
  end

  ############# PRIVATE

  defp check_registry_is_running() do
    Essig.Projections.Registry.is_running?() && Essig.Entities.Registry.is_running?()
  end
end
