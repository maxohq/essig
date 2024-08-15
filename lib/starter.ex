defmodule Starter do
  require Logger

  def supervisor_name do
    app_name = Context.current_app()
    String.to_atom("#{app_name}_Supervisor")
  end

  def stop_supervisor do
    supervisor_name = supervisor_name()

    if Process.whereis(supervisor_name) do
      Supervisor.stop(supervisor_name)
    end
  end

  defp ensure_supervisor_running do
    if Context.current_app() != nil do
      if Process.whereis(supervisor_name()) do
        nil
      else
        opts = [strategy: :one_for_one, name: supervisor_name()]
        Supervisor.start_link([], opts)
      end
    else
      Logger.error("Set the current app via Context.set_current_app()!")
    end
  end

  def add_modules(modules) do
    app_name = Context.current_app()
    supervisor_name = supervisor_name()
    ensure_supervisor_running()

    if Process.whereis(supervisor_name) do
      new_children = children_specs(app_name, modules)
      add_children(supervisor_name, new_children)
    end
  end

  defp add_children(supervisor_name, new_children) do
    Enum.reduce(new_children, {:ok, []}, fn child_spec, {status, started} ->
      case Supervisor.start_child(supervisor_name, child_spec) do
        {:ok, _pid} ->
          Logger.info("Started new child: #{inspect(child_spec.id)}")
          {status, [child_spec.id | started]}

        {:error, {:already_started, _pid}} ->
          Logger.info("Child already running: #{inspect(child_spec.id)}")
          {status, started}

        {:error, reason} ->
          Logger.error("Failed to start child #{inspect(child_spec.id)}: #{inspect(reason)}")
          {:error, started}
      end
    end)
  end

  defp children_specs(app_name, modules) do
    Enum.map(modules, fn module ->
      %{
        id: {app_name, module},
        start: {module, :start_link, [[]]}
      }
    end)
  end
end
