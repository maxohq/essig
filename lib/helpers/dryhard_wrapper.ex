defmodule Essig.Helpers.DryHardWrapper do
  @moduledoc """
  A small wrapper for DryHard to reduce the boilerplate a bit
  """
  defmacro __using__(opts) do
    ecto_schema = Keyword.fetch!(opts, :schema)

    quote do
      alias __MODULE__, as: ME
      use Essig.Repo
      import Ecto.Query, warn: false
      import Ecto.Changeset
      require Dryhard

      # our schema
      alias unquote(ecto_schema)
    end
  end
end
