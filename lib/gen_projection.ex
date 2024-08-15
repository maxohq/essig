defmodule GenProjection do
  defmacro __using__(_) do
    quote do
      use GenServer

      def start_link(args) do
        GenServer.start_link(__MODULE__, args, name: via_tuple())
      end

      defp via_tuple do
        {:via, Registry, {ChildRegistry, {Context.current_app(), __MODULE__}}}
      end

      def current_pid do
        ChildRegistry.get(__MODULE__)
      end
    end
  end
end
