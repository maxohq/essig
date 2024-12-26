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

    ## Subsribe to events
    Essig.Pubsub.subscribe("pg-events.new_events")

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
    actions = [{:reply, from, {state, data}}]
    {:keep_state_and_data, actions}
  end

  def handle_event({:call, from}, {:set_pause_ms, pause_ms}, _state, data) do
    IO.puts("Projections.Runner-> set_pause_ms")
    info(data, "set pause_ms to #{pause_ms}")

    actions = [{:reply, from, :ok}, {:state_timeout, pause_ms, :paused}]
    {:keep_state, %Data{data | pause_ms: pause_ms}, actions}
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
        data = %Data{}
      ) do
    IO.puts("Projections.Runner-> read_from_eventstore: bootstrap")
    Projections.Runner.ReadFromEventStore.run(data)
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
    # when we resume, its similar to bootstrap
    # -> we might have missed uknown amount of events, so its same as bootstrapping from zero
    {:keep_state_and_data, [{:next_event, :internal, :read_from_eventstore}]}
  end

  def handle_event(:info, {:new_events, notification}, status, data) do
    IO.puts("HANDLE NEW EVENTS")
    ## we get a notification from the pubsub, that there are new events
    ## now we need to poll for new events since our last SEQ and send them to the handler module.
    %{
      count: count,
      scope_uuid: scope_uuid,
      max_id: max_id
    } = notification

    IO.inspect(notification, label: "notification")
    IO.inspect(status, label: "status")
    IO.inspect(data, label: "data")
    row = data.row

    data_max_id = row.max_id
    to_fetch = max_id - data_max_id
    seq = row.seq

    # %{
    #   row: %{
    #     projection_uuid: "01940019-225a-76aa-8b24-568a0e0b3ddb",
    #     id: 12,
    #     scope_uuid: "01940019-223b-708b-b7e7-baded5ea9341",
    #     module: "Elixir.Sample.Projections.Proj1",
    #     max_id: 0,
    #     seq: 0,
    #     status: :idle,
    #     setup_done: false,
    #     inserted_at: ~U[2024-12-25 23:13:54Z],
    #     updated_at: ~U[2024-12-25 23:13:54Z]
    #   }
    # } = data

    ### FETCH EVENTS
    events =
      Essig.Cache.request(
        {Essig.EventStoreReads, :read_all_stream_forward, [scope_uuid, seq, to_fetch]}
      )

    IO.inspect(events, label: "events")

    ### UPDATE ACTUAL PROJECTION

    ### UPDATE PROJECTION ROW

    ### UPDATE META TABLE

    # %{
    # count: 2,
    # scope_uuid: "0193ffde-63f1-77e3-9a26-0160116b2ba4",
    # max_id: 4,
    # stream_uuid: "0193ffde-698e-7bdb-a36b-981643742798",
    # txid: 10626169}},
    # :idle,
    # %Essig.Projections.Data{
    #  row: %Essig.Schemas.Projection{
    #   __meta__: #Ecto.Schema.Metadata<:loaded, "essig_projections">,
    #   projection_uuid: "0193ffde-6427-7bb8-a4c7-6739d78e117c",
    #   id: 2,
    #   scope_uuid: "0193ffde-63f1-77e3-9a26-0160116b2ba4",
    #   module: "Elixir.Sample.Projections.Proj1",
    #   max_id: 0,
    #   seq: 0,
    #   status: :idle,
    #   setup_done: false,
    # inserted_at: ~U[2024-12-25 22:09:45Z],
    # updated_at: ~U[2024-12-25 22:09:45Z]},
    # name: Sample.Projections.Proj1,
    # pause_ms: 2,
    # store_max_id: 0,
    # module: Sample.Projections.Proj1}
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

  def info(data, msg) do
    Logger.info("Projection #{inspect(data.name)}: #{msg}")
  end
end
