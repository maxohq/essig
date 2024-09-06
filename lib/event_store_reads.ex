defmodule Essig.EventStoreReads do
  @moduledoc """
  EventStoreReads sets current scope explicitly, for reads.
  This makes it possible to cache with [GenCache](https://github.com/maxohq/gen_cache/)

  Usage:
  ```
   iex> Essig.Cache.request({Essig.EventStoreReads, :read_all_stream_forward, ["0191be93-c178-71a0-8bd8-bcde9f55b7d6", 5,10]})
   iex> Essig.Cache.request({Essig.EventStoreReads, :read_stream_forward, ["0191be93-c178-71a0-8bd8-bcde9f55b7d6", "0191be93-c178-7203-b137-c4e294ca925b", 5, 10]})
  ```
  """
  use Essig.Repo

  def read_stream_forward(scope_uuid, stream_uuid, from_seq, amount) do
    Essig.Context.set_current_scope(scope_uuid)
    Essig.EventStore.ReadStreamForward.run(stream_uuid, from_seq, amount)
  end

  def read_all_stream_forward(scope_uuid, from_id, amount) do
    Essig.Context.set_current_scope(scope_uuid)
    Essig.EventStore.ReadAllStreamForward.run(from_id, amount)
  end

  def read_stream_backward(scope_uuid, stream_uuid, from_seq, amount) do
    Essig.Context.set_current_scope(scope_uuid)
    Essig.EventStore.ReadStreamBackward.run(stream_uuid, from_seq, amount)
  end

  def read_all_stream_backward(scope_uuid, from_id, amount) do
    Essig.Context.set_current_scope(scope_uuid)
    Essig.EventStore.ReadAllStreamBackward.run(from_id, amount)
  end

  def last_seq(scope_uuid, stream_uuid) do
    Essig.Context.set_current_scope(scope_uuid)
    Essig.EventStore.LastSeq.run(stream_uuid)
  end
end
