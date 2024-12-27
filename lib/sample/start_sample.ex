defmodule Sample.StartSample do
  def start do
    scope_uuid = Essig.Context.current_scope()
    Essig.Server.start_scope(scope_uuid)
    ## start projections
    Essig.Server.start_projections([Sample.Projections.Proj1, Sample.Projections.Proj2],
      pause_ms: 2
    )
  end

  def reset do
    Essig.Projections.Runner.reset(Sample.Projections.Proj1)
    Essig.Projections.Runner.reset(Sample.Projections.Proj2)
  end

  def add_events do
    ## insert events
    events = [
      Sample.TestReports.Events.Event1.new(payload: "hello"),
      Sample.TestReports.Events.Event2.new(ops: [%{op: "a"}]),
      Sample.TestReports.Events.Event1.new(payload: "hello"),
      Sample.TestReports.Events.Event2.new(ops: [%{op: "a"}]),
      Sample.TestReports.Events.Event1.new(payload: "hello"),
      Sample.TestReports.Events.Event2.new(ops: [%{op: "a"}]),
      Sample.TestReports.Events.Event1.new(payload: "hello"),
      Sample.TestReports.Events.Event2.new(ops: [%{op: "a"}]),
      Sample.TestReports.Events.Event1.new(payload: "hello"),
      Sample.TestReports.Events.Event2.new(ops: [%{op: "a"}]),
      Sample.TestReports.Events.Event1.new(payload: "hello"),
      Sample.TestReports.Events.Event2.new(ops: [%{op: "a"}]),
      Sample.TestReports.Events.Event1.new(payload: "hello"),
      Sample.TestReports.Events.Event2.new(ops: [%{op: "a"}])
    ]

    stream_uuid = Essig.UUID7.generate()

    Essig.EventStore.append_to_stream(stream_uuid, "trp", 0, events)
  end
end
