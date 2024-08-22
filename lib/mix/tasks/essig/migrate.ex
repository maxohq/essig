defmodule Mix.Tasks.Essig.Migrate do
  use Mix.Task

  @shortdoc "Migrate Essig tables"
  def run(_args) do
    Essig.Release.migrate()
  end
end
