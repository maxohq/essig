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
    res = Enum.map(events, fn event -> handle_event(state, event) end)
    {:ok, res, state}
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
