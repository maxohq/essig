defmodule Essig.Projections.Runner do
  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  def init(name) do
    IO.inspect("STARTING CAST #{name}...")
    {:ok, %{name: name}}
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  ### REGISTRY ############

  def pid_for_name(name) do
    case Registry.lookup(reg_name(), name) do
      [{pid, _}] ->
        pid

      [] ->
        case Essig.Projections.Supervisor.start_child(name) do
          {:ok, pid} -> pid
          {:error, {:already_started, pid}} -> pid
        end
    end
  end

  def list_children do
    Registry.select(reg_name(), [{{:"$1", :"$2", :_}, [], [{{:"$1", :"$2"}}]}])
  end

  defp via_tuple(name) do
    {:via, Registry, {reg_name(), name}}
  end

  def reg_name do
    Essig.Projections.Registry.reg_name()
  end
end
