defmodule Essig.Schemas.Projection do
  use Ecto.Schema

  @primary_key {:projection_uuid, Ecto.UUID, autogenerate: {Essig.UUID7, :generate, []}}
  schema "essig_projections" do
    # this is another "primary" key, used for global ordering (+ and when fetching all stream)
    field(:id, :integer, read_after_writes: true)
    field(:scope_uuid, Ecto.UUID)
    field(:module, :string)
    field(:max_id, :integer, default: 0)
    field(:seq, :integer)

    field(:status, Ecto.Enum,
      values: [:new, :backfilling, :ready, :blocked, :paused],
      default: :new
    )

    field(:setup_done, :boolean, default: false)
    timestamps(type: :utc_datetime)
  end
end
