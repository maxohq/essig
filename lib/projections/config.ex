defmodule Essig.Projections.Config do
  @modules [Essig.Projections.Runner, Essig.Projections.Runner.ReadFromEventStore]

  def set_log_debug() do
    set_log_level(:debug)
  end

  def set_log_info() do
    set_log_level(:info)
  end

  def set_log_level(level) do
    for module <- @modules do
      Logger.put_module_level(module, level)
    end
  end
end
