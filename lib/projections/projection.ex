defmodule Essig.Projections.Projection do
  @callback handle_init_storage(Essig.Projections.Data.t()) :: :ok | {:error, any()}
  @callback handle_reset(Essig.Projections.Data.t()) :: :ok | {:error, any()}
  @callback handle_event(Ecto.Multi.t(), {map(), number()}) :: Ecto.Multi.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour Essig.Projections.Projection

      alias Essig.Projections.Data

      def handle_init_storage(_), do: :ok
      def handle_reset(_), do: :ok

      defoverridable handle_init_storage: 1
      defoverridable handle_reset: 1
    end
  end
end
