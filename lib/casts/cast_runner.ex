defmodule SampleCast1 do
  use Essig.Repo

  def bootstrap() do
    sql = "create table if not exists essig_cast_sample1
    (
      id UUID PRIMARY KEY,
      ecu_group TEXT NOT NULL,
      diagnose_ticket_id INT,
      flashing_ticket_id INT
    );
    "
    Repo.query(sql)
  end

  def handle_events(state, events) do
    Enum.map(events, fn event -> handle_event(state, event) end)
    {:ok, state}
  end

  def handle_event(state, event) do
    IO.puts("SampleCast1: handling #{inspect(event)}")

    {:ok, state}
  end
end

defmodule SampleCast2 do
  use Essig.Repo

  def bootstrap() do
    sql = "create table if not exists essig_cast_sample2
    (
      id UUID PRIMARY KEY,
      ecu_group TEXT NOT NULL,
      diagnose_ticket_id INT,
      flashing_ticket_id INT
    );
    "
    Repo.query(sql)
  end

  def handle_events(state, events) do
    res = Enum.map(events, fn event -> handle_event(state, event) end)
    {:ok, res, state}
  end

  def handle_event(state, event) do
    IO.puts("SampleCast2: handling #{inspect(event)}")

    {:ok, state}
  end
end

defmodule Essig.Casts.CastRunner do
  use GenServer

  def start_link(args) do
    module = Keyword.fetch!(args, :module)
    GenServer.start_link(__MODULE__, args, name: via_tuple(module))
  end

  def send_events(module, events) do
    pid = Essig.Casts.Registry.get(module)
    GenServer.call(pid, {:send_events, events})
  end

  def init(args) do
    module = Keyword.fetch!(args, :module)
    apply(module, :bootstrap, [])
    {:ok, %{module: module, seq: 0, max_id: 0}}
  end

  def via_tuple(module) do
    Essig.Casts.Registry.via(module)
  end

  def handle_call({:send_events, events}, _from, state) do
    module = Map.fetch!(state, :module)
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
    %{state | seq: new_seq, max_id: new_max_id}
  end
end
