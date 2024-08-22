defmodule Essig.EventStore.ReadAllStreamForward do
  alias Essig.Schemas.Event
  use Essig.Repo

  def run(from_id, amount) do
    query(from_id, amount) |> Repo.all()
  end

  def query(from_id, amount) do
    from(event in Event)
    |> where([event], event.id > ^from_id)
    |> order_by(asc: :id)
    |> limit(^amount)
  end
end