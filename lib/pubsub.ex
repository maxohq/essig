defmodule Essig.Pubsub do
  def broadcast(topic, message) do
    Phoenix.PubSub.broadcast(Essig.PubSub, topic, message)
  end

  def subscribe(topic) do
    Phoenix.PubSub.subscribe(Essig.PubSub, topic)
  end

  def unsubscribe(topic) do
    Phoenix.PubSub.unsubscribe(Essig.PubSub, topic)
  end
end
