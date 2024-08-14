defmodule ChildRegistry do
  require Logger

  def register({app_name, module}, pid) do
    Registry.register(__MODULE__, {app_name, module}, pid)
  end

  def get(module) do
    app_name = Context.current_app()

    case Registry.lookup(__MODULE__, {app_name, module}) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  def ensure_started do
    case Registry.start_link(keys: :unique, name: ChildRegistry) do
      {:ok, _} ->
        :ok

      {:error, {:already_started, _}} ->
        :ok

      error ->
        Logger.error("Failed to start ChildRegistry: #{inspect(error)}")
        throw({:error, :registry_start_failed})
    end
  end
end
