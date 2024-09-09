defmodule Essig.Casts2.Server do
  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  def init(name) do
    {:ok, %{name: name}}
  end

  def for_name(name) do
    case Registry.lookup(reg_name(), name) do
      [{pid, _}] ->
        pid

      [] ->
        case Essig.Casts2.Supervisor.start_child(name) do
          {:ok, pid} -> pid
          {:error, {:already_started, pid}} -> pid
        end
    end
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  def list_children do
    Registry.select(reg_name(), [{{:"$1", :"$2", :_}, [], [{{:"$1", :"$2"}}]}])
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  defp via_tuple(name) do
    {:via, Registry, {reg_name(), name}}
  end

  def reg_name do
    Essig.Casts2.Registry.reg_name()
  end
end
