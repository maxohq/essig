defmodule Scopes.DynamicSupervisor do
  # Automatically defines child_spec/1
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(scope) do
    Essig.Context.set_current_scope(scope)
    spec = %{id: {Essig.Scopes.Server, scope}, start: {Essig.Scopes.Server, :start_link, [scope]}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
