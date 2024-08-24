defmodule Essig.Casts.DbFeed do
  use Essig.Repo

  def hydrate_cast(module) do
    stream = scoped_events() |> Repo.cursor_based_stream(max_rows: 100)
    Essig.Casts.CastRunner.send_events(module, stream)

    Enum.reduce(stream, %{}, fn _event, _acc ->
      nil
      # entity = Vecufy.TestReports.Handler.handle(acc, event)
      # %TestReportProcess{entity | seq: event.seq}
    end)
  end

  def scoped_events do
    scope_uuid = Essig.Context.current_scope()
    from e in Essig.Schemas.Event, where: e.scope_uuid == ^scope_uuid, order_by: [asc: :id]
  end
end
