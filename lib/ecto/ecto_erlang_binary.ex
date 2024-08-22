defmodule Ecto.EctoErlangBinary do
  @moduledoc """
  A custom Ecto type for handling the serialization of arbitrary
  data types stored as binary data in the database. Requires the
  underlying DB field to be a binary.
  """
  use Ecto.Type
  def type, do: :binary

  @doc """
  Provides custom casting rules for params. Nothing changes here.
  We only need to handle deserialization.
  """
  def cast(:any, term), do: {:ok, term}
  def cast(term), do: {:ok, term}

  @doc """
  Convert the raw binary value from the database back to
  the desired term.
  """
  def load(raw_binary),
    do: {:ok, from_binary(raw_binary)}

  @doc """
  Converting the data structure to binary for storage.
  """
  def dump(term), do: {:ok, to_binary(term)}

  defp to_binary(term) do
    Essig.Helpers.Compressor.compress(term) |> Base.encode64()
  end

  defp from_binary(nil), do: nil

  defp from_binary(string) do
    Base.decode64!(string) |> Essig.Helpers.Compressor.uncompress()
  end
end
