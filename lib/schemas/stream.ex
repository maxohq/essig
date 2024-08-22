defmodule Essig.Schemas.Stream do
  use Ecto.Schema

  @primary_key {:stream_uuid, Ecto.UUID, autogenerate: {Essig.Ecto.UUID7, :generate, []}}
  schema "essig_streams" do
    # this is another "primary" key, used for global ordering (+ and when fetching all stream)
    field(:id, :integer, read_after_writes: true)
    field(:scope_uuid, Ecto.UUID)
    field(:stream_type, :string)
    field(:seq, :integer, default: 0)
    timestamps(type: :utc_datetime)
  end
end
