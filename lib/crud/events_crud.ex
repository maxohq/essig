defmodule Es.Crud.EventsCrud do
  use Helpers.DryHardWrapper, schema: Es.Schemas.Event

  @resource Dryhard.config(Event, Repo, "es_events")
  @tocast [:app_uuid, :stream_uuid, :seq, :event_type, :data, :meta]
  @toreq [:app_uuid, :stream_uuid, :seq, :event_type, :data, :meta]

  # Common CRUD functions
  Dryhard.paginate(@resource)
  Dryhard.list(@resource)
  Dryhard.get!(@resource)
  Dryhard.get(@resource)
  Dryhard.new(@resource)
  Dryhard.create(@resource, &ME.changeset/2)

  @doc false
  def changeset(entity, attrs) do
    entity
    |> cast(attrs, @tocast)
    |> validate_required(@toreq)
    |> unique_constraint([:stream_uuid, :seq])
  end
end
