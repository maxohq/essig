defmodule Essig.SandRepo do
  @moduledoc """
  This is special SandRepo, that allows checking out a single connection.
  We use this when getting a DB advisory lock and releasing it afterwards.
  This is not possible with the standard Ecto.Repo outside of a transaction.

  To keep the configuration overhead low, we use dynamic config (init -callback) and
  copy the main config for the Essig.Repo with a few tweaks.
  This means the DB config stays unchanged.
  """

  use Ecto.Repo,
    otp_app: :essig,
    adapter: Ecto.Adapters.Postgres

  use EctoCursorBasedStream

  @impl true
  def init(_type, _config) do
    special_config = [
      telemetry_prefix: [:essig, :sand_repo],
      pool: Ecto.Adapters.SQL.Sandbox
    ]

    main_config = Application.get_env(:essig, Essig.Repo)
    config = Keyword.merge(main_config, special_config)

    {:ok, config}
  end

  defmacro __using__(_) do
    quote do
      alias Essig.SandRepo
      require Ecto.Query
      import Ecto.Query
      import Ecto.Changeset
    end
  end
end
