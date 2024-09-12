defmodule Projections.Projection do
  @callback init_storage(Essig.Projections.Data.t()) :: :ok | {:error, any()}
  @callback handle_event(Ecto.Multi.t(), {map(), number()}) :: Ecto.Multi.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour Projections.Projection

      alias Essig.Projections.Data

      def init_storage(_), do: :ok

      defoverridable init_storage: 1
    end
  end
end
