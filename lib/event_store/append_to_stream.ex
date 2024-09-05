defmodule Essig.EventStore.AppendToStream do
  use Essig.Repo

  def run(stream_uuid, stream_type, expected_seq, events) do
    # To ensure sequential inserts only, we use locking.
    # The likelihood of this triggering in production is low, but still possible.
    # Locks are across all OS processes, since we use Postgres for this.
    Essig.PGLock.with_lock("es-insert", fn ->
      run_unprotected(stream_uuid, stream_type, expected_seq, events)
    end)
  end

  defp run_unprotected(stream_uuid, stream_type, expected_seq, events) do
    multi(stream_uuid, stream_type, expected_seq, events)
    |> Repo.transaction()
  end

  def multi(stream_uuid, stream_type, expected_seq, events) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:stream, fn _repo, _changes ->
      ensure_stream_exists(stream_uuid, stream_type)
    end)
    |> Ecto.Multi.run(:is_expected_seq, fn _repo, %{stream: stream} ->
      ensure_expected_seq(stream, expected_seq)
    end)
    |> Ecto.Multi.run(:event_payloads, fn _repo, %{stream: stream} ->
      prepare_events(stream, events)
    end)
    |> Ecto.Multi.run(:insert_events, fn _repo, %{event_payloads: event_payloads} ->
      insert_events(event_payloads)
    end)
    |> Ecto.Multi.run(:update_seq, fn _repo, %{stream: stream, insert_events: insert_events} ->
      last_event = Enum.at(insert_events, -1)
      Essig.Crud.StreamsCrud.update_stream(stream, %{seq: last_event.seq})
    end)
    |> Ecto.Multi.run(:signal_new_events, fn _repo, _ ->
      signal_new_events(stream_uuid)
    end)
  end

  defp ensure_stream_exists(stream_uuid, stream_type) do
    scope_uuid = Essig.Context.current_scope()

    with {:ok, stream} <-
           Essig.Crud.StreamsCrud.upsert_stream(%{
             stream_type: stream_type,
             stream_uuid: stream_uuid,
             scope_uuid: scope_uuid
           }) do
      # we need to reload, so that we get the latest seq value
      stream = Repo.reload(stream)

      if stream.stream_type == stream_type do
        {:ok, stream}
      else
        {:error, {:stream_type_mismatch, [stream.stream_type, stream_type]}}
      end
    end
  end

  defp ensure_expected_seq(stream, seq) do
    if stream.seq == seq do
      {:ok, true}
    else
      {:error, {:seq_mismatch, [stream.seq, seq]}}
    end
  end

  defp prepare_events(stream, events) do
    scope_uuid = Essig.Context.current_scope()
    meta = Essig.Context.current_meta()

    Enum.with_index(events)
    |> Enum.map(fn {item, index} ->
      %{
        scope_uuid: scope_uuid,
        seq: stream.seq + index + 1,
        stream_uuid: stream.stream_uuid,
        stream_type: stream.stream_type,
        event_type: item.__struct__.__json_serde_alias__(),
        data: item,
        meta: meta
      }
    end)
    |> Essig.Helpers.Result.ok()
  end

  defp insert_events(event_payloads) do
    Enum.reduce_while(event_payloads, [], fn event_payload, acc ->
      case Essig.Crud.EventsCrud.create_event(event_payload) do
        {:ok, event} -> {:cont, [event | acc]}
        {:error, _} = error -> {:halt, error}
      end
    end)
    |> case do
      {:error, _} = error -> error
      events -> {:ok, Enum.reverse(events)}
    end
  end

  defp signal_new_events(stream_uuid) do
    scope_uuid = Essig.Context.current_scope()
    bin_uuid = Ecto.UUID.dump!(scope_uuid)
    stream_uuid = Ecto.UUID.dump!(stream_uuid)

    {:ok, _} =
      Repo.query("insert into essig_signals(scope_uuid, stream_uuid) values ($1, $2)", [
        bin_uuid,
        stream_uuid
      ])

    {:ok, true}
  end
end
