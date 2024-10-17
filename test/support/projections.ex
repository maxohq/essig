defmodule SampleProjection1 do
  use Essig.Projections.Projection
  use Essig.Repo

  def init_storage(_data) do
    :ok
  end

  def handle_event(multi, {_event, _seq}) do
    multi
  end
end

defmodule SampleProjection2 do
  use Essig.Projections.Projection
  use Essig.Repo

  def init_storage(_data) do
    :ok
  end

  def handle_event(multi, {_event, _seq}) do
    multi
  end
end
