defmodule Essig.Projections.SeqChecker do
  @moduledoc """
  Checks, that given Cast modules reached certain SEQ value
  """

  def check_reached(modules, seq) do
    conditions =
      Enum.map(modules, fn module ->
        %{and: [[:>=, :seq, seq], [:=, :key, module]]}
      end)

    q = %{or: conditions, project: [:key, :seq]}
    res = Essig.Projections.MetaTable.query(q)
    Enum.count(res) == Enum.count(modules)
  end

  def check_reached(modules, seq, max_id) do
    conditions =
      Enum.map(modules, fn module ->
        %{and: [[:>=, :seq, seq], [:>=, :max_id, max_id], [:=, :key, module]]}
      end)

    q = %{or: conditions, project: [:key, :seq, :max_id]}
    res = Essig.Projections.MetaTable.query(q)
    Enum.count(res) == Enum.count(modules)
  end
end
