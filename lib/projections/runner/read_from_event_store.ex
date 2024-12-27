defmodule Projections.Runner.ReadFromEventStore do
  alias Essig.Projections.Data
  alias Projections.Runner.Common
  require Logger

  def run(data = %Data{row: row, pause_ms: pause_ms, store_max_id: store_max_id} = data) do
    IO.inspect(data, label: "ReadFromEventStore - data")
    scope_uuid = Essig.Context.current_scope()
    amount_of_events_per_batch = 10

    events = Common.fetch_events(scope_uuid, row.max_id, amount_of_events_per_batch)
    IO.inspect(events, label: "ReadFromEventStore - EVENTS")

    multi =
      Enum.reduce(events, Ecto.Multi.new(), fn event, acc_multi ->
        data.module.handle_event(acc_multi, {event, event.id})
      end)

    if length(events) > 0 do
      last_event = List.last(events)

      info(data, "CURRENT MAX ID #{last_event.id}")
      # not sure, what to do with response. BUT: projections MUST NEVER fail.
      {:ok, _multi_results} = Essig.Repo.transaction(multi) |> IO.inspect()

      if last_event.id != store_max_id do
        info(data, "paused for #{pause_ms}ms...")

        row =
          Common.update_external_state(data, row, %{max_id: last_event.id, seq: last_event.seq})

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
          Common.update_external_state(data, row, %{
            max_id: last_event.id,
            seq: last_event.seq,
            status: :idle
          })

        {:next_state, :idle, %Data{data | row: row}}
      end
    else
      info(data, "EMPTY EVENTS")
      row = Common.update_external_state(data, row, %{status: :idle})
      {:next_state, :idle, %Data{data | row: row}}
    end
  end

  def info(data, msg) do
    Logger.info("Projection #{inspect(data.name)}: #{msg}")
  end
end
