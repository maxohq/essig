defmodule Starter.Supervisor do
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

  def ensure_supervisor_running do
    cond do
      Context.current_app() != nil ->
        cond do
          pid = Process.whereis(supervisor_name()) ->
            {:ok, pid}

          true ->
            opts = [strategy: :one_for_one, name: supervisor_name()]
            Supervisor.start_link([], opts)
        end

      true ->
        Logger.error("Set the current app via Context.set_current_app()!")
        {:error, :missing_current_app}
    end
  end
end
