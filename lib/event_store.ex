defmodule Es.EventStore do
  use Essig.Repo

  def append_to_stream(stream_uuid, stream_type, expected_seq, events) do
    with {:ok, res} <-
           Es.EventStore.AppendToStream.run(stream_uuid, stream_type, expected_seq, events) do
      events = res.insert_events
      stream = res.update_seq
      {:ok, %{stream: stream, events: events}}
    end
  end

  def read_stream_forward(stream_uuid, from_seq, amount) do
    Es.EventStore.ReadStreamForward.run(stream_uuid, from_seq, amount)
  end

  def read_all_stream_forward(from_id, amount) do
    Es.EventStore.ReadAllStreamForward.run(from_id, amount)
  end

  def read_stream_backward(stream_uuid, from_seq, amount) do
    Es.EventStore.ReadStreamBackward.run(stream_uuid, from_seq, amount)
  end

  def read_all_stream_backward(from_id, amount) do
    Es.EventStore.ReadAllStreamBackward.run(from_id, amount)
  end

  def last_seq(stream_uuid) do
    Es.EventStore.LastSeq.run(stream_uuid)
  end
end
