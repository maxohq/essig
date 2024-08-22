defmodule Es.Crud.EventsCrudTest do
  use Scoped.DataCase
  alias Es.Crud.EventsCrud
  alias Es.Crud.StreamsCrud

  test "check on required fields" do
    {:error, changeset} = EventsCrud.create_event(%{})
    errors = errors_on(changeset)

    assert Map.keys(errors) |> Enum.sort() == [
             :app_uuid,
             :data,
             :event_type,
             :meta,
             :seq,
             :stream_uuid
           ]

    assert Map.get(errors, :seq) == ["can't be blank"]
    assert Map.get(errors, :stream_uuid) == ["can't be blank"]
    assert Map.get(errors, :event_type) == ["can't be blank"]
    assert Map.get(errors, :data) == ["can't be blank"]
    assert Map.get(errors, :meta) == ["can't be blank"]
  end

  test "creates proper events" do
    stream_uuid = Ecto.UUID7.generate()
    app_uuid = Ecto.UUID7.generate()

    {:ok, _stream} =
      StreamsCrud.create_stream(%{
        app_uuid: app_uuid,
        stream_uuid: stream_uuid,
        stream_type: "user",
        seq: 1
      })

    payload = %Vecufy.TestReports.Events.TicketMatchAdded{match_kind: "some"}

    {:ok, event} =
      EventsCrud.create_event(%{
        seq: 1,
        stream_uuid: stream_uuid,
        app_uuid: app_uuid,
        stream_type: "user",
        event_type: "user.create",
        data: payload,
        meta: %{}
      })

    assert event.event_uuid
    assert event.stream_uuid == stream_uuid
    assert event.app_uuid == app_uuid
  end
end
