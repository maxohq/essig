defmodule Migrations.Migration004 do
  use Ecto.Migration

  def change do
    alter table(:essig_signals) do
      add(:count, :integer, null: false)
      add(:max_id, :bigint, null: false)
    end

    execute """
            CREATE OR REPLACE FUNCTION notify_new_events()
              RETURNS TRIGGER AS $$
              DECLARE
                payload JSON;
              BEGIN
                -- Function to notify on new transactions (events) via pg_notify
                payload := json_build_object(
                  'scope_uuid', NEW.scope_uuid,
                  'stream_uuid', NEW.stream_uuid,
                  'txid', NEW.txid,
                  'count', NEW.count,
                  'max_id', NEW.max_id
                );

                PERFORM pg_notify('new_events', payload::TEXT);
                RETURN NEW;
              END;
              $$ LANGUAGE plpgsql;
            """,
            "DROP FUNCTION notify_new_events();"
  end
end
