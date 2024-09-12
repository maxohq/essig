defmodule Sample.Projections.Proj1 do
  use Projections.Projection
  use Essig.Repo
  require Logger

  @impl Projections.Projection
  def handle_event(multi, {map, index}) do
    Ecto.Multi.run(multi, {:event, index}, fn _repo, _changes ->
      IO.inspect(map.data, label: "index-#{index}")
      {:ok, 1}
    end)
  end

  @impl Projections.Projection
  def init_storage(data = %Data{}) do
    Logger.info("RUNNING INIT STORAGE for #{__MODULE__} with name #{inspect(data.name)}")
    Repo.query("create table if not exists projection_proj1 (id integer, data text)")
    :ok
  end
end