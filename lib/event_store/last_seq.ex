defmodule Es.EventStore.LastSeq do
  use Scoped.Repo

  def run(stream_uuid) do
    stream = Es.Crud.StreamsCrud.get_stream(stream_uuid)
    (stream && stream.seq) || 0
  end
end
