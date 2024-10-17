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
    end
  end
end
