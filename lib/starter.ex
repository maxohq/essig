defmodule Starter do
  require Logger

  def stop_supervisor do
    app_name = Context.current_app()
    supervisor_name = String.to_atom("#{app_name}_Supervisor")

    if Process.whereis(supervisor_name) do
      Supervisor.stop(supervisor_name)
    end
  end

  def supervise_modules(modules) do
    app_name = Context.current_app()
    supervisor_name = String.to_atom("#{app_name}_Supervisor")

    # Ensure ChildRegistry is started
    ChildRegistry.ensure_started()

    children = children_specs(app_name, modules)
    Logger.info("Children to be supervised: #{inspect(children)}")

    if app_name != nil do
      start_children(children, supervisor_name)
    else
      Logger.error("Set the current app via Context.set_current_app()!")
    end
  end

  def add_modules(modules) do
    app_name = Context.current_app()
    supervisor_name = String.to_atom("#{app_name}_Supervisor")

    if Process.whereis(supervisor_name) do
      new_children = children_specs(app_name, modules)
      add_children(supervisor_name, new_children)
    else
      supervise_modules(modules)
    end
  end

  defp start_children(children, supervisor_name) do
    opts = [strategy: :one_for_one, name: supervisor_name]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        Logger.info("Supervisor started successfully with PID: #{inspect(pid)}")
        {:ok, pid}

      {:error, {:shutdown, reason}} ->
        Logger.error("Failed to start supervisor due to child failure: #{inspect(reason)}")
        {:error, {:child_failure, reason}}

      {:error, reason} ->
        Logger.error("Failed to start supervisor: #{inspect(reason)}")
        {:error, reason}
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
