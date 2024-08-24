defmodule EventStore.BaseQuery do
  alias Essig.Schemas.Event
  use Essig.Repo

  def query() do
    scope_uuid = Essig.Context.current_scope()

    from(event in Event)
    |> where([event], event.scope_uuid == ^scope_uuid)
  end
end
