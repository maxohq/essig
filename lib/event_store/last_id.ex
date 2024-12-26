defmodule Essig.EventStore.LastId do
  @moduledoc """
  Get the last serial event ID in the current scope
  """
  use Essig.Repo

  def run() do
    scope_uuid = Essig.Context.current_scope()

    Essig.Schemas.Event
    |> where([e], e.scope_uuid == ^scope_uuid)
    |> order_by([e], desc: e.id)
    |> select([:id])
    |> limit(1)
    |> Repo.one()
    |> case do
      nil -> 0
      event -> event.id
    end
  end
end
