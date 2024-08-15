defmodule HandlersHandler1 do
  use GenHandler

  def push(element) do
    ResponseWrapper.cast(current_pid(), {:push, element})
  end

  def pop() do
    ResponseWrapper.call(current_pid(), :pop)
  end

  def all() do
    ResponseWrapper.call(current_pid(), :all)
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
