defmodule Entities.Entity1 do
  use Casts.GenEntityHandler

  def push(uuid, element) do
    ResponseWrapper.cast(current_pid(uuid), {:push, element})
  end

  def pop(uuid) do
    ResponseWrapper.call(current_pid(uuid), :pop)
  end

  def all(uuid) do
    ResponseWrapper.call(current_pid(uuid), :all)
  end

  # Callbacks

  @impl true
  def init(stack) do
    {:ok, stack}
  end

  @impl true
  def handle_call(:pop, _from, []) do
    {:reply, nil, []}
  end

  def handle_call(:pop, _from, [head | tail]) do
    {:reply, head, tail}
  end

  def handle_call(:all, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:push, element}, state) do
    {:noreply, [element | state]}
  end
end
