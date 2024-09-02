defmodule Essig.EventStore do
  use Essig.Repo

  def append_to_stream(stream_uuid, stream_type, expected_seq, events) do
    with {:ok, res} <-
           Essig.EventStore.AppendToStream.run(stream_uuid, stream_type, expected_seq, events) do
      events = res.insert_events
      stream = res.update_seq

      scope_uuid = Essig.Context.current_scope()

      # Broadcast the events
      Enum.each(events, fn event ->
        Phoenix.PubSub.broadcast(
          Essig.PubSub,
          "events:#{scope_uuid}",
          {:new_event, event}
        )
      end)

      {:ok, %{stream: stream, events: events}}
    end
  end

  def read_stream_forward(stream_uuid, from_seq, amount) do
    Essig.EventStore.ReadStreamForward.run(stream_uuid, from_seq, amount)
  end

  def read_all_stream_forward(from_id, amount) do
    Essig.EventStore.ReadAllStreamForward.run(from_id, amount)
  end

  def read_stream_backward(stream_uuid, from_seq, amount) do
    Essig.EventStore.ReadStreamBackward.run(stream_uuid, from_seq, amount)
  end

  def read_all_stream_backward(from_id, amount) do
    Essig.EventStore.ReadAllStreamBackward.run(from_id, amount)
  end

  def last_seq(stream_uuid) do
    Essig.EventStore.LastSeq.run(stream_uuid)
  end
end
