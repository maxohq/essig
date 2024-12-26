defmodule Projections.Runner.ReadFromEventStore do
  alias Essig.Projections.Data
  require Logger

  def run(data = %Data{row: row, pause_ms: pause_ms, store_max_id: store_max_id}) do
    scope_uuid = Essig.Context.current_scope()
    amount_of_events_per_batch = 10
    events = fetch_events(scope_uuid, row.max_id, amount_of_events_per_batch)

    multi =
      Enum.reduce(events, Ecto.Multi.new(), fn event, acc_multi ->
        data.module.handle_event(acc_multi, {event, event.id})
      end)

    if length(events) > 0 do
      last_event = List.last(events)

      info(data, "at #{last_event.id}")
      # not sure, what to do with response. BUT: projections MUST NEVER fail.
      {:ok, _multi_results} = Essig.Repo.transaction(multi) |> IO.inspect()

      if last_event.id != store_max_id do
        info(data, "paused for #{pause_ms}ms...")
        row = update_external_state(data, row, %{max_id: last_event.id, seq: last_event.seq})

        # need more events, with a pause
        actions = [
          {:next_event, :internal, :paused},
          {:state_timeout, pause_ms, :paused}
        ]

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

  defp update_external_state(data, row, updates) do
    # we also fetch the latest events max ID.
    updates = Map.merge(updates, %{max_id: max_events_id()})
    Essig.Projections.MetaTable.update(data.name, updates)

    {:ok, row} = Essig.Crud.ProjectionsCrud.update_projection(row, updates)
    row
  end

  ## we cache the call to the latest event ID for 1 second
  defp max_events_id() do
    scope_uuid = Essig.Context.current_scope()

    Essig.Cache.request(
      {Essig.EventStoreReads, :last_id, [scope_uuid]},
      ttl: :timer.seconds(1)
    )
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
