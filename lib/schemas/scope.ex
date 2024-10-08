defmodule Essig.Schemas.Scope do
  use Ecto.Schema

  @primary_key {:scope_uuid, Ecto.UUID, autogenerate: {Essig.UUID7, :generate, []}}
  schema "essig_scopes" do
    # this is another "primary" key, used for global ordering (+ and when fetching all stream)
    field(:id, :integer, read_after_writes: true)
    field(:name, :string)
    field(:max_id, :integer, default: 0)
    field(:seq, :integer)
    timestamps(type: :utc_datetime)
  end
end
