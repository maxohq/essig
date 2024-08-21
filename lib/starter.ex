defmodule Starter do
  def supervisor_name, do: Starter.Supervisor.supervisor_name()
  def stop_supervisor, do: Starter.Supervisor.stop_supervisor()

  def add_casts(modules) do
    ensure_started!()

    with {:ok, list} <- Starter.EntityHandlers.add_handlers(modules) do
      Enum.map(list, fn {_scope_name, module} ->
        Casts.MetaTable.update(module, %{})
      end)
    end
  end

  def remove_casts(modules) do
    ensure_started!()
    Starter.EntityHandlers.remove_handlers(modules)

    Enum.map(modules, fn module ->
      Casts.MetaTable.delete(module)
    end)
  end

  defp ensure_started!() do
    Context.assert_current_scope!()
    Scopes.Server.start_link(Context.current_scope())
    Casts.MetaTable.init()
    Entities.MetaTable.init()
  end
end
