defmodule Essig.Casts.SeqChecker do
  @moduledoc """
  Checks, that given Cast modules reached certain SEQ value
  """

  def check_reached(modules, seq) do
    conditions =
      Enum.map(modules, fn module ->
        %{and: [[:>=, :seq, seq], [:=, :key, module]]}
      end)

    q = %{or: conditions, project: [:key, :seq]}
    res = Essig.Casts.MetaTable.query(q)
    Enum.count(res) == Enum.count(modules)
  end
end
