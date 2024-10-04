defmodule Migrations.Migration005 do
  use Ecto.Migration

  def change do
    drop_if_exists table(:essig_casts)

    create table(:essig_projections, primary_key: false) do
      add(:id, :bigserial, primary_key: true)
      add(:projection_uuid, :uuid, null: false, default: fragment("gen_random_uuid()"))
      add(:scope_uuid, :uuid, null: false)
      add(:module, :string, null: false)
      add(:max_id, :integer, null: false)
      add(:seq, :integer, null: false)
      add(:status, :string, null: false)
      add(:setup_done, :boolean, null: false)
      timestamps(type: :utc_datetime_usec, default: fragment("now()"))
    end

    create(index(:essig_projections, [:projection_uuid], unique: true))
    create(index(:essig_projections, [:scope_uuid]))
    create(index(:essig_projections, [:scope_uuid, :module], unique: true))
  end
end
