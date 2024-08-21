defmodule Casts.GenCastHandler do
  defmacro __using__(_) do
    quote do
      use GenServer

      def start_link(args) do
        GenServer.start_link(__MODULE__, args, name: via_tuple())
      end

      defp via_tuple do
        Casts.Registry.via(__MODULE__)
      end

      def current_pid do
        Casts.Registry.get(__MODULE__)
      end
    end
  end
end
