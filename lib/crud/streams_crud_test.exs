defmodule Es.Crud.StreamsCrudTest do
  use Essig.DataCase
  alias Es.Crud.StreamsCrud

  test "check on required fields" do
    {:error, changeset} = StreamsCrud.create_stream(%{})
    errors = errors_on(changeset)
    assert Map.keys(errors) == [:scope_uuid, :stream_type]
    assert Map.get(errors, :stream_type) == ["can't be blank"]
  end

  test "creates a minimal stream record" do
    scope_uuid = Ecto.UUID7.generate()

    {:ok, stream} =
      StreamsCrud.create_stream(%{scope_uuid: scope_uuid, stream_type: "user", seq: 1})

    assert stream.stream_uuid
  end

  test "prevents duplicates" do
    uuid = Ecto.UUID7.generate()
    scope_uuid = Ecto.UUID7.generate()

    {:ok, stream} =
      StreamsCrud.create_stream(%{
        stream_type: "user",
        seq: 1,
        stream_uuid: uuid,
        scope_uuid: scope_uuid
      })

    assert stream.stream_uuid == uuid

    {:error, changeset} =
      StreamsCrud.create_stream(%{
        stream_type: "user",
        seq: 1,
        stream_uuid: uuid,
        scope_uuid: scope_uuid
      })

    assert errors_on(changeset) == %{stream_uuid: ["has already been taken"]}
  end

  test "updates the seq on equal streams (upsert_stream)" do
    uuid = Ecto.UUID7.generate()
    scope_uuid = Ecto.UUID7.generate()

    {:ok, stream} =
      StreamsCrud.upsert_stream(%{
        stream_type: "user",
        seq: 1,
        stream_uuid: uuid,
        scope_uuid: scope_uuid
      })

    assert stream.stream_uuid == uuid
    assert stream.seq == 1

    {:ok, stream2} =
      StreamsCrud.upsert_stream(%{
        stream_type: "user",
        seq: 2,
        stream_uuid: uuid,
        scope_uuid: scope_uuid
      })

    assert stream2.stream_uuid == uuid
    assert stream2.seq == 2
  end
end
