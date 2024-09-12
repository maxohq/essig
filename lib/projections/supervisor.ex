defmodule Essig.Projections.Supervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: reg_name())
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(name) do
    spec = {Essig.Projections.Runner, name}
    DynamicSupervisor.start_child(reg_name(), spec)
  end

  def reg_name do
    scope_name = Essig.Context.current_scope()
    "#{__MODULE__}_#{scope_name}" |> String.to_atom()
  end
end
