defmodule Sample.TestReports.Events.Event1 do
  @moduledoc """
  """
  use Essig.Event, name: "sample.event1"
  defstruct [:payload]
end

defmodule Sample.TestReports.Events.Event2 do
  @moduledoc """
  """
  defstruct [:ops]
  use Essig.Event, name: "sample.event2"
end

defmodule Sample.TestReports.Events.Event3 do
  @moduledoc """
  """
  use Essig.Event, name: "sample.event3"
  defstruct [:path]
end

defmodule Sample.TestReports.Events.Event4 do
  @moduledoc """
  """
  use Essig.Event, name: "sample.event4"
  defstruct [:tasks]
end
