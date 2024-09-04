defmodule Migrations.Migration002 do
  use Ecto.Migration

  def change do
    alter table(:essig_events) do
      add(:txid, :bigint)
      add(:snapmin, :bigint)
    end

    execute "
            CREATE OR REPLACE FUNCTION essig_add_txid_snapmin()
            RETURNS TRIGGER AS $$
            BEGIN
                -- we add current transaction id and minimal LSN
                -- based on suggestions here: https://github.com/josevalim/sync/blob/main/priv/repo/migrations/20240806131210_create_publication.exs

                NEW.txid := pg_current_xact_id();
                NEW.snapmin := pg_snapshot_xmin(pg_current_snapshot());
                RETURN NEW;
            END;
            $$ LANGUAGE plpgsql;
            ",
            "DROP FUNCTION essig_add_txid_snapmin()"

    execute "
            CREATE OR REPLACE TRIGGER essig_add_txid_to_events
            BEFORE INSERT OR UPDATE ON essig_events
            FOR EACH ROW
            EXECUTE FUNCTION essig_add_txid_snapmin();
            ",
            "DROP TRIGGER essig_add_txid_to_events;"
  end
end
