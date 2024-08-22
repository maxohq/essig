defmodule Essig.Helpers.Compressor do
  def compress(v) do
    v |> :erlang.term_to_binary() |> :zlib.compress()
  end

  def uncompress(v) do
    v |> :zlib.uncompress() |> :erlang.binary_to_term()
  end
end
