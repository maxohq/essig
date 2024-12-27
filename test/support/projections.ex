defmodule SampleProjection1 do
  use Essig.Projections.Projection
  use Essig.Repo

  def handle_init_storage(_data) do
    :ok
  end

  def handle_event(multi, data, {_event, _seq}) do
    {multi, data}
  end
end

defmodule SampleProjection2 do
  use Essig.Projections.Projection
  use Essig.Repo

  def handle_init_storage(_data) do
    :ok
  end

  def handle_event(multi, data, {_event, _seq}) do
    {multi, data}
  end
end
