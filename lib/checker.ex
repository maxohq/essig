defmodule Essig.Checker do
  @moduledoc """
  A small dev-only module to test the event store.
  """
  def run do
    scope_uuid = Essig.UUID7.generate()
    stream_uuid = Essig.UUID7.generate()
    run(scope_uuid, stream_uuid)
  end

  def run(scope_uuid, stream_uuid) do
    Essig.Server.start_scope(scope_uuid)

    seq = Essig.EventStore.last_seq(stream_uuid)

    {:ok, %{events: _events}} =
      Essig.EventStore.append_to_stream(stream_uuid, "trp", seq, [
        %Sample.TestReports.Events.MasterReportAdded{path: "local/path/to", report: "report 1"},
        %Sample.TestReports.Events.MasterReportAdded{path: "local/path/to", report: "report 2"},
        %Sample.TestReports.Events.MasterReportAdded{path: "local/path/to", report: "report 3"}
      ])
  end
end
