defmodule Essig.EventStore.ReadStreamBackward do
  use Essig.Repo
  alias Essig.Schemas.Event

  def run(stream_uuid, from_seq, amount) do
    query(stream_uuid, from_seq, amount) |> Repo.all()
  end

  def query(stream_uuid, from_seq, amount) do
    from(Event)
    |> where([event], event.stream_uuid == ^stream_uuid)
    |> where([event], event.seq < ^from_seq)
    |> order_by(desc: :seq)
    |> limit(^amount)
  end
end