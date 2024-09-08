defmodule MyGenServer do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    Phoenix.PubSub.subscribe(Essig.PubSub, pubsub_topic())
    {:ok, state}
  end

  def handle_info({:new_event, event}, state) do
    # Handle the event
    IO.inspect(Essig.Context.current_scope(), label: "Current scope")
    IO.inspect(event, label: "Received event")
    {:noreply, state}
  end

  defp pubsub_topic() do
    scope_uuid = Essig.Context.current_scope()
    "events:#{scope_uuid}"
  end
end
