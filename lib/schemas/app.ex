defmodule Es.Schemas.App do
  use Ecto.Schema

  @primary_key {:app_uuid, Ecto.UUID, autogenerate: {Ecto.UUID7, :generate, []}}
  schema "es_apps" do
    # this is another "primary" key, used for global ordering (+ and when fetching all stream)
    field :id, :integer, read_after_writes: true
    field :name, :string
    field :max_id, :integer, default: 0
    field :seq, :integer
    timestamps(type: :utc_datetime)
  end
end
