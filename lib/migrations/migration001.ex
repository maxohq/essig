defmodule Migrations.Migration001 do
  use Ecto.Migration

  def change do
    create table(:es_streams) do
      add(:stream_uuid, :uuid, null: false, default: fragment("gen_random_uuid()"))
      add(:stream_type, :string, null: false)
      add(:seq, :integer, null: false, default: 0)
      timestamps(type: :utc_datetime, updated_at: false, default: fragment("now()"))
    end

    create(index(:es_streams, [:stream_uuid], unique: true))

    create table(:es_events, primary_key: false) do
      add(:id, :bigserial, primary_key: true)
      add(:event_id, :uuid, null: false, default: fragment("gen_random_uuid()"))
      add(:event_type, :string, null: false)
      add(:stream_uuid, references(:es_streams, column: :stream_uuid, type: :uuid), null: false)
      add(:stream_type, :string, null: false)
      add(:seq, :integer, null: false)
      add(:data, :jsonb, default: fragment("'{}'"))
      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create(index(:es_events, [:event_id], unique: true))
    create(index(:es_events, [:stream_uuid]))
    create(index(:es_events, [:stream_uuid, :seq], unique: true))

    create table(:es_subscriptions) do
      add(:stream_uuid, :uuid, null: false)
      add(:name, :string, null: false)
      add(:last_seen, :integer, null: false)
      timestamps(type: :utc_datetime, updated_at: false, default: fragment("now()"))
    end

    create(index(:es_subscriptions, [:stream_uuid, :name], unique: true))
  end
end
