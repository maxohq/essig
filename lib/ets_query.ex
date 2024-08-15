defmodule EtsQuery do
  def build_match_spec(query_spec) do
    case query_spec do
      %{or: conditions} when is_list(conditions) ->
        Enum.map(conditions, &build_condition/1)

      %{and: conditions} when is_list(conditions) ->
        [build_and_condition(conditions)]

      [:and | conditions] when is_list(conditions) ->
        [build_and_condition(conditions)]

      condition when is_map(condition) ->
        [build_and_condition([condition])]

      _ ->
        raise ArgumentError, "Invalid query specification"
    end
  end

  defp build_and_condition(conditions) do
    {pattern, guard} =
      Enum.reduce(conditions, {[:"$1", :"$2"], []}, fn condition, {pattern, guard} ->
        {new_pattern, new_guard} = build_condition_clause(condition)
        {pattern, guard ++ new_guard}
      end)

    {pattern, guard, [:"$$"]}
  end

  defp build_condition([:=, key, value]) do
    build_condition(%{key => value})
  end

  defp build_condition(%{} = condition) do
    {pattern, guard} = build_condition_clause(condition)
    {[:"$1", :"$2" | pattern], guard, [:"$$"]}
  end

  defp build_condition_clause(%{} = condition) do
    Enum.reduce(condition, {[], []}, fn {key, value}, {pattern, guard} ->
      var = :"$#{length(pattern) + 3}"
      {pattern ++ [var], guard ++ [{:==, var, value}]}
    end)
  end

  defp build_and_condition(conditions) do
    {pattern, guard} =
      Enum.reduce(conditions, {[:"$1", :"$2"], []}, fn condition, {pattern, guard} ->
        {new_pattern, new_guard} = build_condition_clause(condition)
        {pattern, guard ++ new_guard}
      end)

    {pattern, guard, [:"$$"]}
  end

  defp build_condition([:=, key, value]) do
    build_condition(%{key => value})
  end

  defp build_condition(%{} = condition) do
    {pattern, guard} = build_condition_clause(condition)
    {[:"$1", :"$2" | pattern], guard, [:"$$"]}
  end

  defp build_condition_clause(%{} = condition) do
    Enum.reduce(condition, {[], []}, fn {key, value}, {pattern, guard} ->
      var = :"$#{length(pattern) + 3}"
      {pattern ++ [var], guard ++ [{:==, var, value}]}
    end)
  end
end
