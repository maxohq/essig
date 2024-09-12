defmodule Essig.Projections.Runner do
  use GenStateMachine
  use Essig.Projections.RegHelpers

  require Logger

  alias Essig.Projections.Data

  # Client API

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    module = Keyword.get(opts, :module, name)
    pause_ms = Keyword.get(opts, :pause_ms, 1000)

    GenStateMachine.start_link(
      __MODULE__,
      %{
        name: name,
        module: module,
        pause_ms: pause_ms
      },
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
    {:keep_state_and_data, [{:reply, from, {state, data}}]}
  end

  def handle_event({:call, from}, {:set_pause_ms, pause_ms}, _state, data) do
    info(data, "set pause_ms to #{pause_ms}")

    {:keep_state, %Data{data | pause_ms: pause_ms},
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

  def handle_event(:internal, :init_storage, :bootstrap, data = %Data{}) do
    info(data, "INIT STORAGE")
    data.module.init_storage(data)
    :keep_state_and_data
  end

  def handle_event(
        :internal,
        :read_from_eventstore,
        :bootstrap,
        data = %Data{row: row, name: name, pause_ms: pause_ms, store_max_id: store_max_id}
      ) do
    scope_uuid = Essig.Context.current_scope()
    events = fetch_events(scope_uuid, row.max_id, 10)

    multi = Ecto.Multi.new()

    {row, multi} =
      Enum.reduce(events, {row, multi}, fn event, {acc_row, acc_multi} ->
        ### handle row START
        acc_row = Map.put(acc_row, :max_id, event.id)
        acc_row = Map.put(acc_row, :count, acc_row.count + 1)
        ### handle row DONE

        ## accumulate statements into ecto multi
        acc_multi = data.module.handle_event(acc_multi, {event, acc_row.count})
        {acc_row, acc_multi}
      end)

    info(data, "at #{row.max_id}")
    # not sure, what to do with response. BUT: projections MUST NEVER fail.
    {:ok, _multi_results} = Essig.Repo.transaction(multi) |> IO.inspect()
    Essig.Projections.MetaTable.set(name, %{max_id: row.max_id, count: row.count})

    if row.max_id != store_max_id do
      # need more events, with a pause
      actions = [
        {:next_event, :internal, :paused},
        {:state_timeout, pause_ms, :paused}
      ]

      info(data, "paused for #{pause_ms}ms...")
      {:keep_state, %Data{data | row: row}, actions}
    else
      # finished...
      info(data, "finished")
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

  def info(data, msg) do
    Logger.info("Projection #{inspect(data.name)}: #{msg}")
  end
end
