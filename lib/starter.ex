defmodule Starter do
  def supervisor_name, do: Starter.Supervisor.supervisor_name()
  def stop_supervisor, do: Starter.Supervisor.stop_supervisor()

  def add_handlers(modules) do
    HandlerMeta.init()
    Starter.Handlers.add_handlers(modules)
  end

  def remove_handlers(modules) do
    Starter.Handlers.remove_handlers(modules)
  end
end
