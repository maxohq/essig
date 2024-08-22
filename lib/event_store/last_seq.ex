defmodule Essig.EventStore.LastSeq do
  use Essig.Repo

  def run(stream_uuid) do
    stream = Es.Crud.StreamsCrud.get_stream(stream_uuid)
    (stream && stream.seq) || 0
  end
end
