defmodule Essig.Projections.Supervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: reg_name())
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(opts) do
    child_spec = %{
      id: Essig.Projections.Runner,
      start: {Essig.Projections.Runner, :start_link, [opts]},
      restart: :transient
    }

    DynamicSupervisor.start_child(reg_name(), child_spec)
  end

  def reg_name do
    scope_name = Essig.Context.current_scope()
    "#{__MODULE__}_#{scope_name}" |> String.to_atom()
  end
end
