defmodule Migrations.Migration003 do
  use Ecto.Migration

  def change do
    create table(:essig_signals, primary_key: false) do
      add(:id, :bigserial, primary_key: true)
      add(:scope_uuid, :uuid, null: false, default: fragment("gen_random_uuid()"))
      add(:stream_uuid, :uuid, null: false)
      add(:txid, :bigint)
      add(:snapmin, :bigint)
    end

    execute "
            -- Trigger on singals table, to notify  on new transactions (events) via pg_notify
            CREATE OR REPLACE TRIGGER essig_add_txid_to_signals
            BEFORE INSERT OR UPDATE ON essig_signals
            FOR EACH ROW
            EXECUTE FUNCTION essig_add_txid_snapmin();
            ",
            "DROP TRIGGER essig_add_txid_to_signals;"

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
                  'snapmin', NEW.snapmin
                );

                PERFORM pg_notify('pg-events.new_events', payload::TEXT);
                RETURN NEW;
              END;
              $$ LANGUAGE plpgsql;
            """,
            "DROP FUNCTION notify_new_events();"

    execute "
            -- Trigger to notify on new transactions (events) via pg_notify
            CREATE TRIGGER signals_notify_new_events
              BEFORE INSERT ON essig_signals
              FOR EACH ROW
              EXECUTE PROCEDURE notify_new_events();
            ",
            "DROP TRIGGER signals_notify_new_events;"
  end
end
