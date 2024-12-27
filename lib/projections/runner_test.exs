defmodule Essig.Projections.RunnerTest do
  use Essig.DataCase

  defmodule TestProjection do
    use Essig.Projections.Projection
    use Essig.Repo
    require Logger

    @impl Essig.Projections.Projection
    def handle_event(multi, data, {map, seq}) do
      multi =
        Ecto.Multi.run(multi, {:event, seq}, fn _repo, _changes ->
          IO.inspect(map.data, label: "seq-#{seq}")
          {:ok, 1}
        end)

      {multi, data}
    end

    @impl Essig.Projections.Projection
    def handle_init_storage(data = %Data{}) do
      Logger.info("RUNNING INIT STORAGE for #{__MODULE__} with name #{inspect(data.name)}")
      Repo.query("create table if not exists #{table_name(data)} (id integer, data text)")
      :ok
    end

    def table_name(data) do
      "projection_#{inspect(data.module)}"
    end
  end

  describe "basic features" do
    test "works" do
      scope_uuid = Essig.UUID7.generate()
      Essig.Context.set_current_scope(scope_uuid)
      Essig.Server.start_scope(scope_uuid)
      Essig.Server.start_projections([TestProjection], pause_ms: 2)

      # this is required to make sure the projection is finished
      Process.sleep(5)

      # Essig.Projections.SeqChecker.await([TestProjection], 0, 10)
      # pid = Essig.Server.get_projection(TestProjection)
      # GenServer.stop(pid)
    end
  end
end
