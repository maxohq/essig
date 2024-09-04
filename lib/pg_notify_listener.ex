defmodule Essig.PGNotifyListener do
  @moduledoc """
  Receives notifications from the database (signals table / new_events channel)
  and rebroadcasts them to the `Phoenix.PubSub` system.

  This is a small payload once per transaction.
  """
  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, [])

  def init(_arg) do
    config = Essig.Repo.config()
    config = Keyword.put(config, :auto_reconnect, true)
    {:ok, pid} = Postgrex.Notifications.start_link(config)
    Postgrex.Notifications.listen(pid, "new_events")
    {:ok, []}
  end

  def handle_info({:notification, _connection_pid, _ref, _channel, payload}, state) do
    with {:ok, map} = Jason.decode(payload) do
      rebroadcast(map)
    end

    {:noreply, state}
  end

  def rebroadcast(map) do
    map = Essig.Helpers.Map.atomize_keys(map)
    Essig.Pubsub.broadcast("new_events", {:new_events, map})
  end
end
