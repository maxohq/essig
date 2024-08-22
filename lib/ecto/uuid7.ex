defmodule Ecto.UUID7 do
  @moduledoc """
  wrapper around Uniq.UUID
  """
  def generate() do
    Uniq.UUID.uuid7()
  end
end
