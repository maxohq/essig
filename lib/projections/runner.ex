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
  alias Essig.Projections.Runner.Common

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

  def reset(name) do
    GenStateMachine.call(via_tuple(name), :reset)
  end

  # Callbacks

  @impl true
  def init(%{name: name, pause_ms: pause_ms, module: module} = data) do
    scope_uuid = Essig.Context.current_scope()
    debug(data, "Init with pause_ms #{pause_ms}")
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
      [{:next_event, :internal, :init_storage}, {:next_event, :internal, :load_from_eventstore}]
    }
  end

  ########### `call` EVENTS handlers -> correspond to GenStateMachine.call on the process

  @impl true
  def handle_event({:call, from}, :get_state_data, state, data) do
    actions = [{:reply, from, {state, data}}]
    {:keep_state_and_data, actions}
  end

  def handle_event({:call, from}, {:set_pause_ms, pause_ms}, state, data) do
    debug(data, "set_pause_ms - #{state} - #{pause_ms}")

    actions = [{:reply, from, :ok}, {:state_timeout, pause_ms, :paused}]
    {:keep_state, %Data{data | pause_ms: pause_ms}, actions}
  end

  def handle_event({:call, from}, :pause, state, data) do
    debug(data, "pause - #{state}")

    {:keep_state_and_data,
     [
       {:reply, from, :ok},
       {:next_event, :internal, :paused},
       # endless timeout, cancels the timeout
       {:state_timeout, :infinity, :paused}
     ]}
  end

  def handle_event({:call, from}, :resume, state, data) do
    debug(data, "resume - #{state}")
    {:keep_state_and_data, [{:reply, from, :ok}, {:next_event, :internal, :resume}]}
  end

  def handle_event({:call, from}, :reset, state, data) do
    debug(data, "reset - #{state}")

    # 1. call the projection-specific logic
    data.module.handle_reset(data)

    # 2. update the projection state to start from max_id = 0
    row =
      Common.update_external_state(data, data.row, %{
        max_id: 0,
        status: :idle
      })

    # 3. switch to init sequence handling: init_storage + load_from_eventstore
    actions = [
      {:reply, from, :ok},
      {:next_event, :internal, :init_storage},
      {:next_event, :internal, :load_from_eventstore}
    ]

    {:next_state, :bootstrap, %Data{data | row: row}, actions}
  end

  ########### `internal` EVENTS handlers

  def handle_event(:internal, :init_storage, :bootstrap, data = %Data{}) do
    debug(data, "init_storage - #{:bootstrap}")
    data.module.handle_init_storage(data)
    :keep_state_and_data
  end

  def handle_event(:internal, :load_from_eventstore, state, data = %Data{}) do
    debug(data, "load_from_eventstore - #{state}")
    Essig.Projections.Runner.ReadFromEventStore.run(data)
  end

  # resume reading, pause timeout triggered
  def handle_event(:state_timeout, :paused, _, _) do
    {:keep_state_and_data, [{:next_event, :internal, :load_from_eventstore}]}
  end

  # internal pause event, nothing, timeout will trigger resume
  def handle_event(:internal, :paused, _, %{name: _name}) do
    :keep_state_and_data
  end

  # resume reading, extenal resume event
  def handle_event(:internal, :resume, _, _) do
    # when we resume, its similar to bootstrap
    # -> we might have missed uknown amount of events, so its same as bootstrapping from zero
    {:keep_state_and_data, [{:next_event, :internal, :load_from_eventstore}]}
  end

  ########### EXTERNAL EVENTS, here from PUBSUB subscription

  def handle_event(:info, {:new_events, notification}, state, data)
      when state in [:bootstrap, :idle] do
    debug(data, "new_events - #{state}")
    ## we get a notification from the pubsub, that there are new events
    %{max_id: max_id} = notification

    # We update the max_id to the value from the notification and switch to :load_from_eventstore internal event handler
    actions = [{:next_event, :internal, :load_from_eventstore}]
    {:keep_state, %Data{data | store_max_id: max_id}, actions}
  end

  ########### HELPERS

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

  def debug(data, msg) do
    Logger.debug("Projections.Runner-> #{inspect(data.name)}: #{msg}")
  end
end
