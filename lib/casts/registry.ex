defmodule Casts.Registry do
  def start_link(_) do
    Context.assert_current_scope!()
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

  def register(module, pid) do
    Registry.register(reg_name(), via(module), pid)
  end

  def get(module) do
    case Registry.lookup(reg_name(), via(module)) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  def via(module) do
    {:via, Registry, {reg_name(), module}}
  end

  def reg_name do
    scope_name = Context.current_scope()
    "#{__MODULE__}_#{scope_name}" |> String.to_atom()
  end
end
