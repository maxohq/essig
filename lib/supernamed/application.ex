defmodule Supernamed.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: ChildRegistry}
    ]

    opts = [strategy: :one_for_one, name: Supernamed.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
