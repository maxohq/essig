defmodule Es.Schemas.Event do
  use Ecto.Schema

  @primary_key {:event_uuid, Ecto.UUID, autogenerate: {Ecto.UUID7, :generate, []}}
  schema "es_events" do
    # this is another "primary" key, used for global ordering (+ and when fetching all stream)
    field(:id, :integer, read_after_writes: true)
    field(:scope_uuid, Ecto.UUID)
    field(:stream_uuid, Ecto.UUID)
    field(:event_type, :string)

    # we are not using Ecto.EctoJsonSerde, since nested serialization does not work properly
    field(:data, Ecto.EctoErlangBinary)
    field(:meta, Ecto.EctoErlangBinary)

    field(:seq, :integer)

    # no updated_at!
    timestamps(type: :utc_datetime_usec, updated_at: false)
  end
end
