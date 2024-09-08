defmodule Essig.EventStore.ReadStreamForward do
  use Essig.Repo

  def run(stream_uuid, from_seq, amount) do
    query(stream_uuid, from_seq, amount) |> Repo.all()
  end

  def query(stream_uuid, from_seq, amount) do
    Essig.EventStore.BaseQuery.query()
    |> where([event], event.stream_uuid == ^stream_uuid)
    |> where([event], event.seq > ^from_seq)
    |> order_by(asc: :id)
    |> limit(^amount)
  end
end
