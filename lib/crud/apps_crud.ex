defmodule Es.Crud.AppsCrud do
  use Helpers.DryHardWrapper, schema: Es.Schemas.App

  @resource Dryhard.config(App, Repo, "es_apps")

  @tocast [:id, :name, :max_id, :seq]
  @toreq [:name]

  # Common CRUD functions
  Dryhard.list(@resource)
  Dryhard.paginate(@resource)
  Dryhard.get!(@resource)
  Dryhard.get(@resource)
  Dryhard.new(@resource)
  Dryhard.create(@resource, &ME.changeset/2)

  Dryhard.upsert(@resource, &ME.upsert_changeset/2,
    on_conflict: {:replace, [:max_id, :seq]},
    conflict_target: [:name]
  )

  Dryhard.update(@resource, &ME.changeset/2)
  Dryhard.change(@resource, &ME.changeset/2)
  Dryhard.delete(@resource)

  def get_app_by_name(name) when is_binary(name) do
    Repo.get_by(App, name: name)
  end

  @doc false
  def changeset(entity, attrs) do
    entity
    |> cast(attrs, @tocast)
    |> validate_required(@toreq)
    |> unique_constraint([:name])
  end

  def upsert_changeset(entity, attrs) do
    entity
    |> cast(attrs, @tocast)
    |> validate_required([:name, :max_id, :seq])
    |> unique_constraint([:name])
  end
end
