defmodule Starter do
  require Logger

  def supervise_modules(modules) do
    app_name = Context.current_app()
    supervisor_name = String.to_atom("#{app_name}_Supervisor")

    # Ensure ChildRegistry is started
    case Registry.start_link(keys: :unique, name: ChildRegistry) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
      error -> 
        Logger.error("Failed to start ChildRegistry: #{inspect(error)}")
        throw({:error, :registry_start_failed})
    end

    children =
      Enum.map(modules, fn module ->
        %{
          id: {app_name, module},
          start: {module, :start_link, [[]]}
        }
      end)

    Logger.info("Children to be supervised: #{inspect(children)}")

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

  def stop_supervisor do
    app_name = Context.current_app()
    supervisor_name = String.to_atom("#{app_name}_Supervisor")

    if Process.whereis(supervisor_name) do
      Supervisor.stop(supervisor_name)
    end
  end
end
