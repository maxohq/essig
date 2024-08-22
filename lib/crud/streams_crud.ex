defmodule Essig.Crud.StreamsCrud do
  use Helpers.DryHardWrapper, schema: Essig.Schemas.Stream

  @resource Dryhard.config(Stream, Repo, "es_streams")
  @tocast [:scope_uuid, :stream_uuid, :stream_type, :seq]
  @toreq [:scope_uuid, :stream_type, :seq]

  # Common CRUD functions
  Dryhard.list(@resource)
  Dryhard.paginate(@resource)
  Dryhard.get!(@resource)
  Dryhard.get(@resource)
  Dryhard.new(@resource)
  Dryhard.create(@resource, &ME.changeset/2)
  Dryhard.update(@resource, &ME.changeset/2)

  Dryhard.upsert(@resource, &ME.changeset/2,
    on_conflict: :nothing,
    conflict_target: [:stream_uuid]
  )

  @doc false
  def changeset(entity, attrs) do
    entity
    |> cast(attrs, @tocast)
    |> validate_required(@toreq)
    |> unique_constraint([:stream_uuid])
  end
end
