defmodule Essig.Repo do
  use Ecto.Repo,
    otp_app: :essig,
    adapter: Ecto.Adapters.Postgres

  use EctoCursorBasedStream

  defmacro __using__(_) do
    quote do
      alias Essig.Repo
      require Ecto.Query
      import Ecto.Query
      import Ecto.Changeset
    end
  end
end
