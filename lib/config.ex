defmodule Essig.Config do
  @moduledoc """
  Essig configuration.
  """

  @doc """
  We need to experiment with different batch sizes.
  `10` is probably too conservative, but useful in development.
  """
  def events_per_batch, do: Application.get_env(:essig, :events_per_batch, 10)

  @doc """
  How long should the fetched events be cached.
  This is only to avoid cache stampedes (lots of requests at the same time),
  no need to cache for long time.
  """
  def events_cache_ttl, do: Application.get_env(:essig, :events_cache_ttl, :timer.seconds(2))
end
