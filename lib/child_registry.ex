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
end
