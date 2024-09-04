defmodule Migrations.Migration002 do
  use Ecto.Migration

  def change do
    alter table(:essig_events) do
      add(:_xid, :bigserial)
      add(:_snapmin, :bigserial)
    end

    execute "
            CREATE OR REPLACE FUNCTION essig_add_xid_snapmin()
            RETURNS TRIGGER AS $$
            BEGIN
                -- we add current transaction id and minimal LSN
                -- based on suggestions here: https://github.com/josevalim/sync/blob/main/priv/repo/migrations/20240806131210_create_publication.exs

                NEW._xid := pg_current_xact_id();
                NEW._snapmin := pg_snapshot_xmin(pg_current_snapshot());
                RETURN NEW;
            END;
            $$ LANGUAGE plpgsql;
            ",
            "DROP FUNCTION essig_add_xid_snapmin()"

    execute "
            CREATE OR REPLACE TRIGGER essig_add_xid_to_events
            BEFORE INSERT OR UPDATE ON essig_events
            FOR EACH ROW
            EXECUTE FUNCTION essig_add_xid_snapmin();
            ",
            "DROP TRIGGER essig_add_xid_to_events;"
  end
end
