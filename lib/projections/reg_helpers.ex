defmodule Essig.Projections.RegHelpers do
  defmacro __using__(_) do
    quote do
      import Essig.Projections.RegHelpers

      defdelegate list_children, to: Essig.Projections.RegHelpers
      defdelegate pid_for_name(name), to: Essig.Projections.RegHelpers
    end
  end

  def pid_for_name(name) do
    case Registry.lookup(reg_name(), name) do
      [{pid, _}] ->
        pid

      [] ->
        case Essig.Projections.Supervisor.start_child(name: name) do
          {:ok, pid} -> pid
          {:error, {:already_started, pid}} -> pid
        end
    end
  end

  def list_children do
    Registry.select(reg_name(), [{{:"$1", :"$2", :_}, [], [{{:"$1", :"$2"}}]}])
  end

  def via_tuple(name) do
    {:via, Registry, {reg_name(), name}}
  end

  def reg_name do
    Essig.Projections.Registry.reg_name()
  end
end
