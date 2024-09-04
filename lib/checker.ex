defmodule Essig.Checker do
  @moduledoc """
  A small dev-only module to test the event store.
  """
  def run do
    scope_uuid = Essig.UUID7.generate()

    Essig.Server.start_scope(scope_uuid)
    Essig.Server.start_casts([SampleCast1])

    stream_uuid = Essig.UUID7.generate()

    {:ok, %{events: events}} =
      Essig.EventStore.append_to_stream(stream_uuid, "trp", 0, [
        %Sample.TestReports.Events.MasterReportAdded{path: "local/path/to", report: "report 1"},
        %Sample.TestReports.Events.MasterReportAdded{path: "local/path/to", report: "report 2"},
        %Sample.TestReports.Events.MasterReportAdded{path: "local/path/to", report: "report 3"}
      ])

    # this will be unnecessary soon
    Essig.Casts.CastRunner.send_events(SampleCast1, events)
  end
end
