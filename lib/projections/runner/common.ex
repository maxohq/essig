defmodule Essig.Projections.Runner.Common do
  alias Essig.Projections.Data

  def fetch_events(scope_uuid, max_id, amount) do
    Essig.Cache.request(
      {Essig.EventStoreReads, :read_all_stream_forward, [scope_uuid, max_id, amount]},
      ttl: Essig.Config.events_cache_ttl()
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
