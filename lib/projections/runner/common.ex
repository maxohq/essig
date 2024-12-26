defmodule Projections.Runner.Common do
  alias Essig.Projections.Data

  def fetch_events(scope_uuid, max_id, amount) do
    Essig.Cache.request(
      {Essig.EventStoreReads, :read_all_stream_forward, [scope_uuid, max_id, amount]},
      # in theory we can cache them forever, the results will never change
      # but we let them expire to reduce app memory usage
      ttl: :timer.minutes(15)
    )
  end

  ## we cache the call to the latest event ID for 1 second
  def max_events_id() do
    max_events_id(Essig.Context.current_scope())
  end

  def max_events_id(scope_uuid) do
    Essig.Cache.request(
      {Essig.EventStoreReads, :last_id, [scope_uuid]},
      ttl: :timer.seconds(1)
    )
  end

  @doc """
  Update the the projections TABLE row + MetaTable entry
  """
  def update_external_state(data = %Data{}, row, updates) do
    Essig.Projections.MetaTable.update(data.name, updates)

    {:ok, row} = Essig.Crud.ProjectionsCrud.update_projection(row, updates)
    row
  end
end
