defmodule Es.Crud.CastsCrud do
  use Helpers.DryHardWrapper, schema: Es.Schemas.Cast

  @resource Dryhard.config(Cast, Repo, "es_casts")

  @tocast [:app_uuid, :module, :status, :max_id, :seq, :setup_done]
  @toreq [:app_uuid, :module, :seq]

  # Common CRUD functions
  Dryhard.list(@resource)
  Dryhard.paginate(@resource)
  Dryhard.get!(@resource)
  Dryhard.get(@resource)
  Dryhard.new(@resource)
  Dryhard.create(@resource, &ME.changeset/2)

  Dryhard.upsert(@resource, &ME.upsert_changeset/2,
    on_conflict: {:replace, [:max_id, :status, :seq]},
    conflict_target: [:app_uuid, :module]
  )

  Dryhard.update(@resource, &ME.changeset/2)
  Dryhard.change(@resource, &ME.changeset/2)
  Dryhard.delete(@resource)

  def get_cast_by_module(module) when is_binary(module) do
    app_uuid = Es.Context.current_scope()
    Repo.get_by(Es.Schemas.Cast, module: module, app_uuid: app_uuid)
  end

  def get_cast_by_module(module) do
    get_cast_by_module(Atom.to_string(module))
  end

  def increment_seq(id, increment) when is_integer(increment) and increment > 0 do
    from(c in Es.Schemas.Cast, where: c.id == ^id)
    |> Repo.update_all(inc: [seq: increment])
  end

  @doc false
  def changeset(entity, attrs) do
    entity
    |> cast(attrs, @tocast)
    |> validate_required(@toreq)
    |> unique_constraint([:app_uuid, :module])
  end

  def upsert_changeset(entity, attrs) do
    entity
    |> cast(attrs, @tocast)
    |> validate_required([:app_uuid, :module, :status, :max_id, :seq])
    |> unique_constraint([:app_uuid, :module])
  end
end
