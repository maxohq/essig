defmodule Essig.GenMetaTable do
  defmacro __using__(table_kind) do
    quote do
      @table_kind unquote(table_kind)

      @moduledoc """
      Provides a way to attach updateable datastructures to module names using ETS tables.
      The ETS table name is based on the current app context for namespacing.

      Namespace: #{@table_kind}
      """

      def init do
        Essig.Context.assert_current_scope!()
        table_name = get_table_name()

        if :ets.whereis(table_name) == :undefined do
          :ets.new(table_name, [:set, :public, :named_table])
        end

        table_name
      end

      def set(module, data) do
        table_name = get_table_name()
        data = Map.put(data, :key, module)
        :ets.insert(table_name, {module, data})
      end

      def update(module, new_data) do
        table_name = get_table_name()

        case :ets.lookup(table_name, module) do
          [{^module, existing_data}] ->
            updated_data = Map.merge(existing_data, new_data)
            :ets.insert(table_name, {module, updated_data})

          [] ->
            new_data = Map.put(new_data, :key, module)
            :ets.insert(table_name, {module, new_data})
        end
      end

      def get(module) do
        table_name = get_table_name()

        case :ets.lookup(table_name, module) do
          [{^module, data}] -> data
          [] -> nil
        end
      end

      def all do
        table_name = get_table_name()
        :ets.tab2list(table_name)
      end

      def delete(module) do
        table_name = get_table_name()
        :ets.delete(table_name, module)
      end

      def delete_all do
        table_name = get_table_name()
        :ets.delete_all_objects(table_name)
      end

      def query(query_spec) do
        table_name = get_table_name()
        match_spec = EtsSelect.build(query_spec)
        :ets.select(table_name, match_spec)
      end

      defp get_table_name do
        scope_name = Essig.Context.current_scope()
        String.to_atom("#{scope_name}_#{@table_kind}")
      end
    end
  end
end
