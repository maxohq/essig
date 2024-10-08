defmodule Migrations.Migration001 do
  use Ecto.Migration

  def up do
    create_scopes()
    create_events()
    create_streams()
    create_casts()
  end

  def down do
    drop_if_exists(table(:essig_scopes))
    drop_if_exists(table(:essig_events))
    drop_if_exists(table(:essig_streams))
    drop_if_exists(table(:essig_casts))
  end

  def create_scopes do
    create table(:essig_scopes, primary_key: false) do
      add(:id, :bigserial, primary_key: true)
      add(:scope_uuid, :uuid, null: false, default: fragment("gen_random_uuid()"))
      add(:name, :string, null: false)
      add(:max_id, :integer, null: false)
      add(:seq, :integer, null: false)
      timestamps(type: :utc_datetime_usec)
    end

    create(index(:essig_scopes, [:scope_uuid], unique: true))
    create(index(:essig_scopes, [:name], unique: true))
  end

  def create_events do
    create table(:essig_events, primary_key: false) do
      add(:id, :bigserial, primary_key: true)
      add(:event_uuid, :uuid, null: false, default: fragment("gen_random_uuid()"))
      add(:scope_uuid, :uuid, null: false)
      add(:stream_uuid, :uuid, null: false)
      ##
      add(:event_type, :string, null: false)
      add(:data, :jsonb, default: fragment("'{}'"))
      add(:meta, :jsonb, default: fragment("'{}'"))
      add(:seq, :integer, null: false)

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create(index(:essig_events, [:event_uuid], unique: true))
    # maybe redundant?, see next
    create(index(:essig_events, [:stream_uuid]))
    create(index(:essig_events, [:stream_uuid, :seq], unique: true))

    create(index(:essig_events, [:scope_uuid]))
    create(index(:essig_events, [:event_type]))
  end

  def create_streams do
    create table(:essig_streams, primary_key: false) do
      add(:id, :bigserial, primary_key: true)
      add(:stream_uuid, :uuid, null: false, default: fragment("gen_random_uuid()"))
      add(:scope_uuid, :uuid, null: false)
      add(:stream_type, :string, null: false)
      add(:seq, :integer, null: false, default: 0)
      timestamps(type: :utc_datetime_usec, default: fragment("now()"))
    end

    create(index(:essig_streams, [:stream_uuid], unique: true))
    create(index(:essig_streams, [:scope_uuid]))
    create(index(:essig_streams, [:stream_type]))
  end

  def create_casts do
    create table(:essig_casts, primary_key: false) do
      add(:id, :bigserial, primary_key: true)
      add(:cast_uuid, :uuid, null: false, default: fragment("gen_random_uuid()"))
      add(:scope_uuid, :uuid, null: false)
      add(:module, :string, null: false)
      add(:max_id, :integer, null: false)
      add(:seq, :integer, null: false)
      add(:status, :string, null: false)
      add(:setup_done, :boolean, null: false)
      timestamps(type: :utc_datetime_usec, default: fragment("now()"))
    end

    create(index(:essig_casts, [:cast_uuid], unique: true))
    create(index(:essig_casts, [:scope_uuid]))
    create(index(:essig_casts, [:scope_uuid, :module], unique: true))
  end
end
