defmodule Essig.Projections.Runner do
  use GenStateMachine
  require Logger

  import Essig.Projections.RegHelpers

  # Client API

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    pause_ms = Keyword.get(opts, :pause_ms, 1000)

    GenStateMachine.start_link(__MODULE__, %{name: name, pause_ms: pause_ms},
      name: via_tuple(name)
    )
  end

  def get_state_data(name) do
    GenStateMachine.call(via_tuple(name), :get_state_data)
  end

  def pause(name) do
    GenStateMachine.call(via_tuple(name), :pause)
  end

  def resume(name) do
    GenStateMachine.call(via_tuple(name), :resume)
  end

  def set_pause_ms(name, pause_ms) do
    GenStateMachine.call(via_tuple(name), {:set_pause_ms, pause_ms})
  end

  # Callbacks

  @impl true
  def init(%{name: name, pause_ms: pause_ms}) do
    scope_uuid = Essig.Context.current_scope()
    Logger.info("Projection #{name}: Init with pause_ms #{pause_ms}")
    row = fetch_last_record(name)
    store_max_id = Essig.EventStoreReads.last_id(scope_uuid)

    {
      :ok,
      :bootstrap,
      %{row: row, name: name, pause_ms: pause_ms, store_max_id: store_max_id},
      [{:next_event, :internal, :ensure_tables}, {:next_event, :internal, :read_from_eventstore}]
    }
  end

  @impl true
  def handle_event({:call, from}, :get_state_data, state, data) do
    {:keep_state_and_data, [{:reply, from, {state, data}}]}
  end

  def handle_event({:call, from}, {:set_pause_ms, pause_ms}, _state, data) do
    Logger.info("Projection #{data.name}: set pause_ms to #{pause_ms}")

    {:keep_state, %{data | pause_ms: pause_ms},
     [{:reply, from, :ok}, {:state_timeout, pause_ms, :paused}]}
  end

  def handle_event({:call, from}, :pause, _state, _data) do
    {:keep_state_and_data,
     [
       {:reply, from, :ok},
       {:next_event, :internal, :paused},
       # endless timeout, cancels the timeout
       {:state_timeout, :infinity, :paused}
     ]}
  end

  def handle_event({:call, from}, :resume, _state, _data) do
    {:keep_state_and_data, [{:reply, from, :ok}, {:next_event, :internal, :resume}]}
  end

  def handle_event(:internal, :ensure_tables, :bootstrap, data) do
    Logger.info("Projection #{data.name}: ensure tables")
    :keep_state_and_data
  end

  def handle_event(
        :internal,
        :read_from_eventstore,
        :bootstrap,
        data = %{row: row, name: name, pause_ms: pause_ms, store_max_id: store_max_id}
      ) do
    scope_uuid = Essig.Context.current_scope()
    events = fetch_events(scope_uuid, row.max_id, 10)

    row =
      Enum.reduce(events, row, fn event, acc ->
        acc = Map.put(acc, :max_id, event.id)
        Map.put(acc, :count, acc.count + 1)
      end)

    Logger.info("Projection #{name}: at #{row.max_id}")
    Essig.Projections.MetaTable.set(name, %{max_id: row.max_id, count: row.count})

    if row.max_id != store_max_id do
      # need more events, with a pause
      actions = [
        {:next_event, :internal, :paused},
        {:state_timeout, pause_ms, :paused}
      ]

      Logger.info("Projection #{data.name}: paused for #{pause_ms}...")
      {:keep_state, %{data | row: row}, actions}
    else
      # finished...
      Logger.info("Projection #{data.name}: finished!")
      {:next_state, :idle, %{data | row: row}}
    end
  end

  # resume reading, pause timeout triggered
  def handle_event(:state_timeout, :paused, :bootstrap, _) do
    {:keep_state_and_data, [{:next_event, :internal, :read_from_eventstore}]}
  end

  # resume reading, pause timeout triggered
  def handle_event(:state_timeout, :paused, :idle, _) do
    {:keep_state_and_data, []}
  end

  # internal pause event, nothing, timeout will trigger resume
  def handle_event(:internal, :paused, _, %{name: _name}) do
    :keep_state_and_data
  end

  # resume reading, extenal resume event
  def handle_event(:internal, :resume, :bootstrap, _) do
    {:keep_state_and_data, [{:next_event, :internal, :read_from_eventstore}]}
  end

  def handle_event(:internal, :resume, :idle, _) do
    {:keep_state_and_data, []}
  end

  defp fetch_last_record(name) do
    case res = Essig.Projections.MetaTable.get(name) do
      nil -> %{max_id: 0, count: 0}
      %{} -> res
    end
  end

  defp fetch_events(scope_uuid, max_id, amount) do
    Essig.Cache.request(
      {Essig.EventStoreReads, :read_all_stream_forward, [scope_uuid, max_id, amount]},
      # in theory we can cache them forever, the results will never change
      # but we let them expire to reduce app memory usage
      ttl: :timer.minutes(15)
    )
  end
end
