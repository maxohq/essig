defmodule Essig.Server do
  import Liveness

  def start_scope(scope) do
    Essig.Context.set_current_scope(scope)
    Essig.Scopes.Server.start_link(scope)

    eventually(fn ->
      Essig.Casts.Registry.is_running?() && Essig.Entities.Registry.is_running?()
    end)

    Essig.Casts.MetaTable.init()
    Essig.Entities.MetaTable.init()
  end

  ############ CASTS

  def start_casts(modules) do
    Enum.map(modules, fn module ->
      Essig.Casts.CastRunner.start_link(module: module)
    end)
  end

  def get_cast(module) do
    Essig.Casts.Registry.get(module)
  end

  ############ ENTITIES

  def start_entity(module, uuid) do
    apply(module, :start_link, [[{:uuid, uuid}]])
  end

  def get_entity(module, uuid) do
    Essig.Entities.Registry.get(module, uuid)
  end
end
