defmodule Essig.PGLock do
  @moduledoc """
  A simple wrapper around pg_try_advisory_lock and pg_advisory_unlock.
  To get a consistent PG connection, it uses a second Repo with pool_size=1.
  This makes it possible to use the same connection for locking and releasing the lock!
  Because releasing the lock on a different connection than the one it was created wont work.
  This is the best workaround I could come up with.


  - Check locks with:

  ```sql
  SELECT locktype, transactionid, virtualtransaction, mode FROM pg_locks;
  ```
  """
  use Essig.RepoSingleConn

  def with_lock(kind, fun) do
    lock_key = :erlang.phash2([Essig.Context.current_scope(), kind])

    case get_lock(lock_key) do
      {:ok, %{rows: [[true]]}} ->
        try do
          fun.()
        after
          release_lock(lock_key)
        end

      _ ->
        {:error, :locked}
    end
  end

  def get_lock(key) do
    Ecto.Adapters.SQL.query(RepoSingleConn, "SELECT pg_try_advisory_lock($1)", [key], [])
  end

  def release_lock(key) do
    Ecto.Adapters.SQL.query(RepoSingleConn, "SELECT pg_advisory_unlock($1)", [key], [])
  end
end
