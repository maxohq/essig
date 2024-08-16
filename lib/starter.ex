defmodule Starter do
  def supervisor_name, do: Starter.Supervisor.supervisor_name()
  def stop_supervisor, do: Starter.Supervisor.stop_supervisor()

  def add_handlers(modules) do
    ensure_started!()

    with {:ok, list} <- Starter.Handlers.add_handlers(modules) |> IO.inspect() do
      Enum.map(list, fn {_app_name, module} ->
        HandlerMeta.update(module, %{})
      end)
    end
  end

  def remove_handlers(modules) do
    ensure_started!()
    Starter.Handlers.remove_handlers(modules)

    Enum.map(modules, fn module ->
      HandlerMeta.delete(module)
    end)
  end

  defp ensure_started! do
    Context.assert_current_app!()
    HandlerMeta.init()
  end
end
