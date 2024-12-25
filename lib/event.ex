defmodule Essig.Event do
  @moduledoc """
  Usage:

    ```elixir
    defmodule MyApp.Events.UserCreated do
      use Essig.Event, name: "user.created"
    end
    ```
  """
  defmacro __using__(opts) do
    name = Keyword.fetch!(opts, :name)

    quote do
      def __essig_event__() do
        unquote(name)
      end

      def new(args \\ %{})

      def new(args) when is_map(args) do
        struct(__MODULE__, args)
      end

      def new(args) when is_list(args) do
        args = Enum.into(args, %{})
        struct(__MODULE__, args)
      end
    end
  end
end
