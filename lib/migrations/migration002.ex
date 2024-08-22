defmodule Migrations.Migration002 do
  use Ecto.Migration

  def change do
    create table(:es_casts, primary_key: false) do
      add(:id, :bigserial, primary_key: true)
      add(:module, :string, null: false)
      add(:status, :string, null: false)
      add(:last_seen, :bigint, null: false, default: 0)
      add(:events_handled, :bigint, null: false, default: 0)
      timestamps(type: :utc_datetime_usec)
    end

    create(index(:es_casts, [:module], unique: true))
  end
end
