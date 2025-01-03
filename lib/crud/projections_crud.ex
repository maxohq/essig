defmodule Essig.Crud.ProjectionsCrud do
  use Essig.Helpers.DryHardWrapper, schema: Essig.Schemas.Projection

  @resource Dryhard.config(Projection, Repo, "es_projections")

  @tocast [:scope_uuid, :module, :status, :max_id, :seq, :setup_done]
  @toreq [:scope_uuid, :module, :seq]

  # Common CRUD functions
  Dryhard.list(@resource)
  Dryhard.paginate(@resource)
  Dryhard.get!(@resource)
  Dryhard.get(@resource)
  Dryhard.new(@resource)
  Dryhard.create(@resource, &ME.changeset/2)

  Dryhard.upsert(@resource, &ME.upsert_changeset/2,
    on_conflict: {:replace, [:max_id, :status, :seq]},
    conflict_target: [:scope_uuid, :module]
  )

  Dryhard.update(@resource, &ME.changeset/2)
  Dryhard.change(@resource, &ME.changeset/2)
  Dryhard.delete(@resource)

  def get_projection_by_module(module) when is_binary(module) do
    scope_uuid = Essig.Context.current_scope()
    Repo.get_by(Essig.Schemas.Projection, module: module, scope_uuid: scope_uuid)
  end

  def get_projection_by_module(module) do
    get_projection_by_module(Atom.to_string(module))
  end

  @doc false
  def changeset(entity, attrs) do
    entity
    |> cast(attrs, @tocast)
    |> validate_required(@toreq)
    |> unique_constraint([:scope_uuid, :module])
  end

  def upsert_changeset(entity, attrs) do
    entity
    |> cast(attrs, @tocast)
    |> validate_required([:scope_uuid, :module, :status, :max_id, :seq])
    |> unique_constraint([:scope_uuid, :module])
  end
end
