defmodule Essig.Schemas.Event do
  use Ecto.Schema

  @primary_key {:event_uuid, Ecto.UUID, autogenerate: {Essig.UUID7, :generate, []}}
  schema "essig_events" do
    # this is another "primary" key, used for global ordering (+ and when fetching all stream)
    field(:id, :integer, read_after_writes: true)
    field(:scope_uuid, Ecto.UUID)
    field(:stream_uuid, Ecto.UUID)
    field(:event_type, :string)

    # we are not using Ecto.EctoJsonSerde, since nested serialization does not work properly
    field(:data, Essig.Ecto.EctoErlangBinary)
    field(:meta, Essig.Ecto.EctoErlangBinary)

    field(:seq, :integer)

    ## transaction metadata
    field(:_xid, :integer, read_after_writes: true)
    field(:_snapmin, :integer, read_after_writes: true)

    # no updated_at!
    timestamps(type: :utc_datetime_usec, updated_at: false)
  end
end
