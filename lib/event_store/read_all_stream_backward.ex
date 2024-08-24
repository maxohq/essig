defmodule Essig.EventStore.ReadAllStreamBackward do
  alias Essig.Schemas.Event
  use Essig.Repo

  def run(from_id, amount) do
    query(from_id, amount) |> Repo.all()
  end

  def query(from_id, amount) do
    EventStore.BaseQuery.query()
    |> where([event], event.id < ^from_id)
    |> order_by(desc: :id)
    |> limit(^amount)
  end
end
