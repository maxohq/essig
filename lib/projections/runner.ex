defmodule Essig.Projections.Runner do
  @moduledoc """
    This module `Essig.Projections.Runner` is a GenStateMachine implementation that manages event sourcing projections.
    Here's a breakdown of its main purposes:

    1. **Event Processing**: It reads events from an event store and processes them sequentially to build/maintain projections (which are typically read-optimized views of data).

    2. **State Management**: It manages different states of the projection processing:
       - `:bootstrap` - Initial loading and processing of events
       - `:idle` - When caught up with all events

    3. **Control Features**:
       - Pause/Resume functionality for event processing
       - Configurable pause duration between processing batches
       - State tracking to remember the last processed event ID

    4. **Durability**:
       - Maintains projection progress in a database
       - Tracks the maximum event ID processed
       - Handles projection state persistence

    5. **Batching**:
       - Processes events in batches (10 events at a time)
       - Uses Ecto.Multi for transactional processing

    6. **Reliability**:
       - Includes caching mechanism for event fetching
       - Designed to be fault-tolerant ("projections MUST NEVER fail")

    Key features include transaction safety, state persistence, configurable processing speeds, and the ability to rebuild projections from the event store when needed.
  """
  use GenStateMachine
  use Essig.Projections.RegHelpers

  require Logger

  alias Essig.Projections.Data

  # Client API

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    module = Keyword.get(opts, :module, name)
    pause_ms = Keyword.get(opts, :pause_ms, 1000)
    init_args = %{name: name, module: module, pause_ms: pause_ms}
    GenStateMachine.start_link(__MODULE__, init_args, name: via_tuple(name))
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
  def init(%{name: name, pause_ms: pause_ms, module: module} = data) do
    scope_uuid = Essig.Context.current_scope()
    info(data, "Init with pause_ms #{pause_ms}")
    row = fetch_last_record(name)
    store_max_id = Essig.EventStoreReads.last_id(scope_uuid)

    data = %Data{
      row: row,
      name: name,
      module: module,
      pause_ms: pause_ms,
      store_max_id: store_max_id
    }

    {
      :ok,
      :bootstrap,
      data,
      [{:next_event, :internal, :init_storage}, {:next_event, :internal, :read_from_eventstore}]
    }
  end

  @impl true
  def handle_event({:call, from}, :get_state_data, state, data) do
    IO.puts("Projections.Runner-> get_state_data")
    {:keep_state_and_data, [{:reply, from, {state, data}}]}
  end

  def handle_event({:call, from}, {:set_pause_ms, pause_ms}, _state, data) do
    IO.puts("Projections.Runner-> set_pause_ms")
    info(data, "set pause_ms to #{pause_ms}")

    {:keep_state, %Data{data | pause_ms: pause_ms},
     [{:reply, from, :ok}, {:state_timeout, pause_ms, :paused}]}
  end

  def handle_event({:call, from}, :pause, _state, _data) do
    IO.puts("Projections.Runner-> pause")

    {:keep_state_and_data,
     [
       {:reply, from, :ok},
       {:next_event, :internal, :paused},
       # endless timeout, cancels the timeout
       {:state_timeout, :infinity, :paused}
     ]}
  end

  def handle_event({:call, from}, :resume, _state, _data) do
    IO.puts("Projections.Runner-> resume")
    {:keep_state_and_data, [{:reply, from, :ok}, {:next_event, :internal, :resume}]}
  end

  def handle_event(:internal, :init_storage, :bootstrap, data = %Data{}) do
    IO.puts("Projections.Runner-> init_storage: bootstrap")
    info(data, "INIT STORAGE")
    data.module.init_storage(data)
    :keep_state_and_data
  end

  def handle_event(
        :internal,
        :read_from_eventstore,
        :bootstrap,
        data = %Data{row: row, pause_ms: pause_ms, store_max_id: store_max_id}
      ) do
    IO.puts("Projections.Runner-> read_from_eventstore: bootstrap")
    multi = Ecto.Multi.new()
    scope_uuid = Essig.Context.current_scope()
    events = fetch_events(scope_uuid, row.max_id, 10)

    multi =
      Enum.reduce(events, multi, fn event, acc_multi ->
        data.module.handle_event(acc_multi, {event, event.seq})
      end)

    if length(events) > 0 do
      last_event = List.last(events)

      info(data, "at #{last_event.id}")
      # not sure, what to do with response. BUT: projections MUST NEVER fail.
      {:ok, _multi_results} = Essig.Repo.transaction(multi) |> IO.inspect()

      if last_event.id != store_max_id do
        # need more events, with a pause
        actions = [
          {:next_event, :internal, :paused},
          {:state_timeout, pause_ms, :paused}
        ]

        info(data, "paused for #{pause_ms}ms...")
        row = update_external_state(data, row, %{max_id: last_event.id, seq: last_event.seq})
        {:keep_state, %Data{data | row: row}, actions}
      else
        # finished...
        info(data, "finished")

        row =
          update_external_state(data, row, %{
            max_id: last_event.id,
            seq: last_event.seq,
            status: :idle
          })

        {:next_state, :idle, %Data{data | row: row}}
      end
    else
      row = update_external_state(data, row, %{status: :idle})
      {:next_state, :idle, %Data{data | row: row}}
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
    case res = Essig.Crud.ProjectionsCrud.get_projection_by_module(name) do
      nil -> init_db_record(name)
      %{} -> res
    end
  end

  defp init_db_record(name) do
    module = Atom.to_string(name)
    scope_uuid = Essig.Context.current_scope()
    args = %{name: name, module: module, scope_uuid: scope_uuid, max_id: 0, seq: 0}

    with {:ok, row} <- Essig.Crud.ProjectionsCrud.create_projection(args) do
      Essig.Projections.MetaTable.update(name, args)
      row
    end
  end

  defp update_external_state(data, row, updates) do
    Essig.Projections.MetaTable.update(data.name, updates)
    {:ok, row} = Essig.Crud.ProjectionsCrud.update_projection(row, updates)
    row
  end

  defp fetch_events(scope_uuid, max_id, amount) do
    Essig.Cache.request(
      {Essig.EventStoreReads, :read_all_stream_forward, [scope_uuid, max_id, amount]},
      # in theory we can cache them forever, the results will never change
      # but we let them expire to reduce app memory usage
      ttl: :timer.minutes(15)
    )
  end

  def info(data, msg) do
    Logger.info("Projection #{inspect(data.name)}: #{msg}")
  end
end
