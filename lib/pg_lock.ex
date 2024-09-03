defmodule Essig.PGLock do
  @moduledoc """
  A simple wrapper around pg_try_advisory_lock and pg_advisory_unlock.
  To get consistent PG connection, it uses SandRepo (which is configured with a Sandbox as pool)

  This makes it possible to use the same connection for locking and releasing the lock!
  Because releasing the lock on a different connection than locking it will fail.
  This is the best workaround I could come up with.
  """
  use Essig.SandRepo

  def with_lock(kind, fun) do
    lock_key = :erlang.phash2("#{kind}-#{Essig.Context.current_scope()}")

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
    Ecto.Adapters.SQL.query(SandRepo, "SELECT pg_try_advisory_lock($1)", [key], [])
  end

  def release_lock(key) do
    Ecto.Adapters.SQL.query(SandRepo, "SELECT pg_advisory_unlock($1)", [key], [])
  end
end
