defmodule Scoped.Repo do
  use Ecto.Repo,
    otp_app: :scoped,
    adapter: Ecto.Adapters.Postgres

  use EctoCursorBasedStream

  defmacro __using__(_) do
    quote do
      alias Scoped.Repo
      require Ecto.Query
      import Ecto.Query
      import Ecto.Changeset
    end
  end
end
