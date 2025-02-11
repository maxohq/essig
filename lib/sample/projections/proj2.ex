defmodule Sample.Projections.Proj2 do
  use Essig.Projections.Projection
  use Essig.Repo
  require Logger

  @impl Essig.Projections.Projection
  def handle_event(multi, data = %Data{}, {_event, index}) do
    multi =
      Ecto.Multi.run(multi, {:event, index}, fn _repo, _changes ->
        # IO.inspect(event.data, label: "index-#{index}")
        Repo.insert_all("projection_proj2", [%{id: index, data: "OK"}])
        {:ok, 1}
      end)

    {multi, data}
  end

  @impl Essig.Projections.Projection
  def handle_init_storage(data = %Data{}) do
    Logger.info("RUNNING INIT STORAGE for #{__MODULE__} with name #{inspect(data.name)}")
    Repo.query("create table if not exists projection_proj2 (id integer, data text)")
    :ok
  end

  @impl Essig.Projections.Projection
  def handle_reset(data = %Data{}) do
    Logger.info("RUNNING RESET for #{__MODULE__} with name #{inspect(data.name)}")
    Repo.query("drop table if exists projection_proj2")
    :ok
  end
end
