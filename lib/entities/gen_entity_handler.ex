defmodule Essig.Entities.GenEntityHandler do
  defmacro __using__(_) do
    quote do
      use GenServer

      alias Essig.Helpers.ResponseWrapper

      def start_link(args) do
        uuid = Keyword.fetch!(args, :uuid)
        GenServer.start_link(__MODULE__, args, name: via_tuple(uuid))
      end

      defp via_tuple(uuid) do
        Essig.Entities.Registry.via(__MODULE__, uuid)
      end

      def current_pid(uuid) do
        Essig.Entities.Registry.get(__MODULE__, uuid)
      end
    end
  end
end
