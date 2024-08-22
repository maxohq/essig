defmodule Essig.Crud.EventsCrudTest do
  use Essig.DataCase
  alias Essig.Crud.EventsCrud
  alias Essig.Crud.StreamsCrud

  test "check on required fields" do
    {:error, changeset} = EventsCrud.create_event(%{})
    errors = errors_on(changeset)

    assert Map.keys(errors) |> Enum.sort() == [
             :data,
             :event_type,
             :meta,
             :scope_uuid,
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
    scope_uuid = Ecto.UUID7.generate()

    {:ok, _stream} =
      StreamsCrud.create_stream(%{
        scope_uuid: scope_uuid,
        stream_uuid: stream_uuid,
        stream_type: "user",
        seq: 1
      })

    payload = %CustomApp.TestReports.Events.TicketMatchAdded{match_kind: "some"}

    {:ok, event} =
      EventsCrud.create_event(%{
        seq: 1,
        stream_uuid: stream_uuid,
        scope_uuid: scope_uuid,
        stream_type: "user",
        event_type: "user.create",
        data: payload,
        meta: %{}
      })

    assert event.event_uuid
    assert event.stream_uuid == stream_uuid
    assert event.scope_uuid == scope_uuid
  end
end
