defmodule Essig.EventStore.AppendToStreamTest do
  use Essig.DataCase

  describe "stream does not exist" do
    setup do
      Essig.Context.set_current_scope(Essig.UUID7.generate())
      stream_uuid = Essig.UUID7.generate()

      e1 = %CustomApp.TestReports.Events.TicketMatchAdded{
        match_kind: "auto",
        id: "1",
        kind: "powertrain"
      }

      e2 = %CustomApp.TestReports.Events.TicketMatchAdded{
        match_kind: "auto",
        id: "2",
        kind: "telematics"
      }

      {:ok, changes} =
        Essig.EventStore.AppendToStream.run(stream_uuid, "test-report-process", 0, [e1, e2])

      %{changes: changes}
    end

    test "creates a new stream (if needed)", %{changes: changes} do
      stream = Map.get(changes, :stream)
      assert stream.seq == 0
    end

    test "updates seq on stream to reflect inserted events (2)", %{changes: changes} do
      stream = Map.get(changes, :update_seq)
      assert stream.seq == 2
    end

    test "generates payloads for events + inserts them", %{changes: changes} do
      stream = Map.get(changes, :stream)
      [e1, e2] = Map.get(changes, :insert_events)
      assert e1.stream_uuid == stream.stream_uuid
      assert e1.event_type == "trp.ticket_match_added"
      assert e1.seq == 1
      assert e2.seq == 2

      assert e1.event_uuid != e2.event_uuid
    end
  end

  describe "stream exists + expected value matches" do
    setup do
      Essig.Context.set_current_scope(Essig.UUID7.generate())
      stream_uuid = Essig.UUID7.generate()

      e1 = %CustomApp.TestReports.Events.TicketMatchAdded{
        match_kind: "auto",
        id: "1",
        kind: "powertrain"
      }

      e2 = %CustomApp.TestReports.Events.TicketMatchAdded{
        match_kind: "auto",
        id: "2",
        kind: "telematics"
      }

      {:ok, _changes} =
        Essig.EventStore.AppendToStream.run(stream_uuid, "test-report-process", 0, [e1, e2])

      ## insert again, with adjusted expected seq value!
      {:ok, changes} =
        Essig.EventStore.AppendToStream.run(stream_uuid, "test-report-process", 2, [e1, e2])

      %{changes: changes}
    end

    test "re-uses existing stream", %{changes: changes} do
      stream = Map.get(changes, :stream)
      assert stream.seq == 2
    end

    test "updates seq on stream to reflect inserted events (2)", %{changes: changes} do
      stream = Map.get(changes, :update_seq)
      assert stream.seq == 4
    end

    test "generates payloads for events + inserts them", %{changes: changes} do
      stream = Map.get(changes, :stream)
      [e1, e2] = Map.get(changes, :insert_events)
      assert e1.stream_uuid == stream.stream_uuid
      assert e1.event_type == "trp.ticket_match_added"
      assert e1.seq == 3
      assert e2.seq == 4

      assert e1.event_uuid != e2.event_uuid
    end
  end

  describe "stream exists, yet expected seq does not match" do
    test "returns errors" do
      Essig.Context.set_current_scope(Essig.UUID7.generate())
      uuid = Essig.UUID7.generate()

      e1 = %CustomApp.TestReports.Events.TicketMatchAdded{
        match_kind: "auto",
        id: "1",
        kind: "powertrain"
      }

      e2 = %CustomApp.TestReports.Events.TicketMatchAdded{
        match_kind: "auto",
        id: "2",
        kind: "telematics"
      }

      # try appending with non-matching seq value
      {:ok, _changes} =
        Essig.EventStore.AppendToStream.run(uuid, "test-report-process", 0, [e1, e2])

      {:error, :is_expected_seq, {:seq_mismatch, [2, 1]}, _changes} =
        Essig.EventStore.AppendToStream.run(uuid, "test-report-process", 1, [e1, e2])
    end
  end

  describe "stream exists, seq matches, yet stream type does not match" do
    test "returns errors" do
      Essig.Context.set_current_scope(Essig.UUID7.generate())
      uuid = Essig.UUID7.generate()

      e1 = %CustomApp.TestReports.Events.TicketMatchAdded{
        match_kind: "auto",
        id: "1",
        kind: "powertrain"
      }

      e2 = %CustomApp.TestReports.Events.TicketMatchAdded{
        match_kind: "auto",
        id: "2",
        kind: "telematics"
      }

      {:ok, _changes} =
        Essig.EventStore.AppendToStream.run(uuid, "test-report-process", 0, [e1, e2])

      {:error, :stream, {:stream_type_mismatch, ["test-report-process", "wrong-stream-type"]},
       _changes} =
        Essig.EventStore.AppendToStream.run(uuid, "wrong-stream-type", 2, [e1, e2])
    end
  end

  describe "appending empty list of events works" do
    test "returns success" do
      Essig.Context.set_current_scope(Essig.UUID7.generate())
      uuid = Essig.UUID7.generate()

      {:ok, changes} =
        Essig.EventStore.AppendToStream.run(uuid, "test-report-process", 0, [])

      assert changes.insert_events == []
    end
  end
end
