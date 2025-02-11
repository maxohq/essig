defmodule CustomApp.TestReports.Events.TicketMatchAdded do
  @moduledoc """
  - a matching ticket was configured
  - we must always have 2 (!!!) subtickets per Test Report process
    - "bootloader" / "appsw"
  - FIELDS
    - [:match_kind, :id, :kind]
    - EXAMPLE
      - %{match_kind: "manual", id: 50, kind: "bootloader"}
      - %{match_kind: "auto", id: 51, kind: "appsw"}
  """
  use Essig.Event, name: "trp.ticket_match_added"
  defstruct [:match_kind, :id, :kind]
end

defmodule CustomApp.TestReports.Events.ReqTestReportsUpdated do
  @moduledoc """
  - there was a change in the required test reports config
  - a value was set OR deleted
  - removal is only allowed for admins!
    - maybe also allow for everyone, we keep the full history anyways
  - normal users can only add requirements
  - LIST of operations
    - `[[name, op, value], [name, op, value]]`
    - EXAMPLE:
      [
        {:fota, :set, true},
        {:fota, :freeze, true},
        {:fota, :set, false},
        {:fota, :freeze, false},
      ]

  """
  use Essig.Event, name: "trp.req_test_reports_updated"
  defstruct [:ops]
end

defmodule CustomApp.TestReports.Events.MasterReportAdded do
  @moduledoc """
  - an xml file with master report data was found in ZIP and could be parsed
  - we store the XML file name, the content is kept in the BinStorage (BinStorageMasterReport) system (can be potentially multiple MBs)
  - we also store the parsed information for the XML file
  - and the event version (?)
  """
  use Essig.Event, name: "trp.master_report_added"
  defstruct [:path, :report]
end

defmodule CustomApp.TestReports.MasterReport do
  defstruct meta: %{},
            tool_versions: [],
            test_components: [],
            test_cases: []
end

defimpl Inspect, for: CustomApp.TestReports.MasterReport do
  def inspect(mreport, _opts) do
    ~s|CustomApp.TestReports.MasterReport<meta: #{show_meta(mreport.meta)}>|
  end

  def show_meta(meta) do
    ~s|{name: #{meta.name}, path: #{meta.path}, date: #{meta.date}, test_type: #{meta.test_type}, test_tool: #{meta.test_tool}}|
  end
end
