defmodule Essig.Casts.CastRunner do
  use GenServer

  ##### PUBLIC API

  def send_events(module, events) do
    pid = Essig.Casts.Registry.get(module)
    GenServer.call(pid, {:send_events, events})
  end

  ######## GENSERVER

  def start_link(args) do
    module = Keyword.fetch!(args, :module)
    GenServer.start_link(__MODULE__, args, name: via_tuple(module))
  end

  def init(args) do
    module = Keyword.fetch!(args, :module)
    apply(module, :bootstrap, [])
    init_data = %{key: module, seq: 0, max_id: 0, module: module}
    Essig.Casts.MetaTable.set(module, init_data)
    {:ok, init_data}
  end

  defp via_tuple(module) do
    Essig.Casts.Registry.via(module)
  end

  def handle_call({:send_events, events}, _from, state) do
    module = Map.fetch!(state, :key)
    {:ok, res, state} = apply(module, :handle_events, [state, events])
    state = update_seq_and_max_id(state, events)
    {:reply, {res, state}, state}
  end

  def handle_call(request, _from, state) do
    {:reply, request, state}
  end

  defp update_seq_and_max_id(state, events) do
    seq = Map.fetch!(state, :seq)
    max_id = Map.fetch!(state, :max_id)
    new_seq = seq + length(events)
    new_max_id = Enum.reduce(events, max_id, fn event, acc -> max(acc, event.id) end)
    Essig.Casts.MetaTable.update(state.module, %{seq: new_seq, max_id: new_max_id})
    %{state | seq: new_seq, max_id: new_max_id}
  end
end
