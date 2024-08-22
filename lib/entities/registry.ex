defmodule Essig.Entities.Registry do
  def start_link(_) do
    Essig.Context.assert_current_scope!()
    Registry.start_link(keys: :unique, name: reg_name())
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def register(module, uuid, pid) do
    Registry.register(reg_name(), via(module, uuid), pid)
  end

  def get(module, uuid) do
    case Registry.lookup(reg_name(), {module, uuid}) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  def via(module, uuid) do
    {:via, Registry, {reg_name(), {module, uuid}}}
  end

  def reg_name do
    scope_name = Essig.Context.current_scope()
    "#{__MODULE__}_#{scope_name}" |> String.to_atom()
  end

  def keys do
    Registry.select(reg_name(), [{{:"$1", :_, :_}, [], [:"$1"]}]) |> Enum.sort()
  end

  def all do
    Registry.select(reg_name(), [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
    |> Enum.sort()
  end
end
