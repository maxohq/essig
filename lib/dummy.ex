# Start a Registry
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: MyApp.Registry}
      # other children...
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

# Define a worker process that registers itself with the Registry
defmodule MyApp.Worker do
  use GenServer

  def start_link(id) do
    GenServer.start_link(__MODULE__, id, name: via_tuple(id))
  end

  defp via_tuple(id) do
    {:via, Registry, {MyApp.Registry, id}}
  end

  # GenServer callbacks...

  def init(id) do
    {:ok, id}
  end
end

# Testing the cleanup process
defmodule MyApp.Test do
  def run do
    # Start a worker process
    {:ok, pid} = MyApp.Worker.start_link(:worker1)

    # Verify the process is registered in the Registry
    case Registry.lookup(MyApp.Registry, :worker1) do
      [{^pid, _value}] ->
        IO.puts("Worker1 is registered in the Registry")

      _ ->
        IO.puts("Worker1 is not found in the Registry")
    end

    # Stop the worker process
    GenServer.stop(pid)
    Process.sleep(100)

    # Verify the registry entry has been cleaned up
    case Registry.lookup(MyApp.Registry, :worker1) do
      [] ->
        IO.puts("Worker1 has been removed from the Registry")

      _ ->
        IO.puts("Worker1 is still in the Registry")
    end
  end
end
