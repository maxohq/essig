defmodule Essig.EventStoreTest do
  use Essig.DataCase
  alias CustomApp.TestReports.Events
  use MnemeDefaults

  setup do
    Essig.Context.set_current_scope(Essig.UUID7.generate())
    :ok
  end

  def init_stream(uuid, seq) do
    {:ok, changes} =
      Essig.EventStore.append_to_stream(uuid, "test-report-process", seq, [
        %Events.ReqTestReportsUpdated{ops: []},
        %Events.ReqTestReportsUpdated{ops: []},
        %Events.ReqTestReportsUpdated{ops: []},
        %Events.ReqTestReportsUpdated{ops: []},
        %Events.ReqTestReportsUpdated{ops: []},
        %Events.ReqTestReportsUpdated{ops: []},
        %Events.ReqTestReportsUpdated{ops: []},
        %Events.ReqTestReportsUpdated{ops: []},
        %Events.ReqTestReportsUpdated{ops: []},
        %Events.ReqTestReportsUpdated{ops: []}
      ])

    Map.get(changes, :events)
  end

  describe "read_all_stream_forward" do
    test "iterates over ALL global events from oldest to newest" do
      uuid1 = Essig.UUID7.generate()
      uuid2 = Essig.UUID7.generate()
      init_stream(uuid1, 0)
      init_stream(uuid2, 0)
      init_stream(uuid1, 10)

      events = Essig.EventStore.read_all_stream_forward(0, 11)
      assert Enum.at(events, 0).stream_uuid == uuid1
      assert Enum.at(events, 0).seq == 1
      assert Enum.at(events, 1).stream_uuid == uuid1
      assert Enum.at(events, 1).seq == 2
      assert Enum.at(events, 9).stream_uuid == uuid1
      assert Enum.at(events, 9).seq == 10
      assert Enum.at(events, 10).stream_uuid == uuid2
      assert Enum.at(events, 10).seq == 1
    end
  end

  describe "read_all_stream_backward" do
    test "iterates over ALL global events from newest to oldest" do
      uuid1 = Essig.UUID7.generate()
      uuid2 = Essig.UUID7.generate()
      # batch 1
      init_stream(uuid1, 0)
      # batch 2
      init_stream(uuid2, 0)
      # batch 3
      last_events = init_stream(uuid1, 10)
      # inc by 1, so so that we get all IDs below max
      max_id = Enum.at(last_events, -1).id + 1

      # read last 11 events, 10 from stream1 and 1 event from stream2
      events = Essig.EventStore.read_all_stream_backward(max_id, 11)
      assert Enum.at(events, 0).stream_uuid == uuid1
      assert Enum.at(events, 0).seq == 20
      assert Enum.at(events, 1).stream_uuid == uuid1
      assert Enum.at(events, 1).seq == 19
      assert Enum.at(events, 9).stream_uuid == uuid1
      assert Enum.at(events, 9).seq == 11
      assert Enum.at(events, 10).stream_uuid == uuid2
      assert Enum.at(events, 10).seq == 10
      max_id = Enum.at(events, 10).id + 1

      events = Essig.EventStore.read_all_stream_backward(max_id, 11)
      assert Enum.at(events, 0).stream_uuid == uuid2
      assert Enum.at(events, 0).seq == 10
      assert Enum.at(events, 1).stream_uuid == uuid2
      assert Enum.at(events, 1).seq == 9

      # last event from batch 1
      assert Enum.at(events, 10).stream_uuid == uuid1
      assert Enum.at(events, 10).seq == 10
    end
  end

  describe "read_stream_backward" do
    test "fetches events from newest to oldest with filters applied" do
      uuid = Essig.UUID7.generate()

      init_stream(uuid, 0)

      {:ok, _a} =
        Essig.EventStore.append_to_stream(uuid, "test-report-process", 10, [
          %Events.TicketMatchAdded{id: 1, kind: "boot", match_kind: "auto"}
        ])

      [e1, e2, e3] = Essig.EventStore.read_stream_backward(uuid, 12, 3)
      assert e1.seq == 11
      assert e2.seq == 10
      assert e3.seq == 9

      [e1, e2, e3] = Essig.EventStore.read_stream_backward(uuid, 9, 3)
      assert e1.seq == 8
      assert e2.seq == 7
      assert e3.seq == 6

      [e1, e2, e3] = Essig.EventStore.read_stream_backward(uuid, 6, 3)
      assert e1.seq == 5
      assert e2.seq == 4
      assert e3.seq == 3

      [e1, e2] = Essig.EventStore.read_stream_backward(uuid, 3, 3)
      assert e1.seq == 2
      assert e2.seq == 1

      assert [] == Essig.EventStore.read_stream_backward(uuid, 0, 3)
    end
  end

  describe "read_stream_forward" do
    test "fetches events from oldest to newest with filters applied" do
      uuid = Essig.UUID7.generate()
      init_stream(uuid, 0)

      {:ok, _a} =
        Essig.EventStore.append_to_stream(uuid, "test-report-process", 10, [
          %Events.TicketMatchAdded{id: 1, kind: "bootloader", match_kind: "auto"}
        ])

      [e1, e2, e3] = Essig.EventStore.read_stream_forward(uuid, 0, 3)
      assert e1.seq == 1
      assert e2.seq == 2
      assert e3.seq == 3

      [e1, e2, e3] = Essig.EventStore.read_stream_forward(uuid, 3, 3)
      assert e1.seq == 4
      assert e2.seq == 5
      assert e3.seq == 6

      [e1, e2, e3] = Essig.EventStore.read_stream_forward(uuid, 6, 3)
      assert e1.seq == 7
      assert e2.seq == 8
      assert e3.seq == 9

      [e1, e2] = Essig.EventStore.read_stream_forward(uuid, 9, 3)
      assert e1.seq == 10
      assert e2.seq == 11

      assert [] == Essig.EventStore.read_stream_forward(uuid, 11, 3)
    end
  end

  describe "serialization" do
    test "supports nested Elixir structs" do
      uuid = "6c90a97a-2f79-4cc0-8798-c5b3efbab499"

      report = %CustomApp.TestReports.MasterReport{
        meta: %{name: "name", path: "path", date: "xxx", test_type: "ooo", test_tool: "xxxx"}
      }

      e1 = %CustomApp.TestReports.Events.MasterReportAdded{report: report}
      {:ok, _} = Essig.EventStore.append_to_stream(uuid, "trp", 0, [e1])
      res = Essig.EventStore.read_stream_forward(uuid, 0, 100)

      auto_assert(
        [
          %Essig.Schemas.Event{
            data: %CustomApp.TestReports.Events.MasterReportAdded{
              report: %CustomApp.TestReports.MasterReport{
                meta: %{
                  date: "xxx",
                  name: "name",
                  path: "path",
                  test_tool: "xxxx",
                  test_type: "ooo"
                }
              }
            },
            event_type: "trp.master_report_added",
            id: 0,
            seq: 1,
            stream_uuid: "6c90a97a-2f79-4cc0-8798-c5b3efbab499"
          }
        ] <- anonym_ids(res)
      )
    end
  end

  describe "respects the current scope" do
    test "when the scope is switched, the events from other scopes are not accessible and the seq order is correct!" do
      scope1 = Essig.Context.current_scope()

      Essig.Server.start_scope(scope1)
      uuid1 = Essig.UUID7.generate()
      init_stream(uuid1, 0)

      scope2 = Essig.UUID7.generate()
      Essig.Server.start_scope(scope2)
      uuid2 = Essig.UUID7.generate()
      init_stream(uuid2, 0)

      # switch to scope1
      Essig.Server.start_scope(scope1)
      events1 = Essig.EventStore.read_all_stream_forward(0, 3)

      # switch to scope2
      Essig.Server.start_scope(scope2)
      events2 = Essig.EventStore.read_all_stream_forward(0, 3)

      assert events1 != events2

      assert Enum.map(events1, & &1.seq) == [1, 2, 3]
      assert Enum.map(events2, & &1.seq) == [1, 2, 3]

      assert Enum.map(events1, & &1.scope_uuid) |> Enum.uniq() == [scope1]
      assert Enum.map(events2, & &1.scope_uuid) |> Enum.uniq() == [scope2]
    end
  end

  def anonym_ids(list) when is_list(list) do
    Enum.map(list, &anonym_ids/1)
  end

  def anonym_ids(map) when is_map(map) do
    Map.put(map, :id, 0)
  end
end
