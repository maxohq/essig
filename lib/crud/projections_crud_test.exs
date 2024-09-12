defmodule Essig.ProjectionsCrudTest do
  use Essig.DataCase
  alias Essig.Crud.ProjectionsCrud

  test "requires name field" do
    {:error, changeset} = ProjectionsCrud.create_projection(%{})
    errors = errors_on(changeset)
    assert Map.keys(errors) == [:module, :seq, :scope_uuid]
    assert Map.get(errors, :module) == ["can't be blank"]
  end

  test "provides defaults for numeric values" do
    uuid = Essig.UUID7.generate()

    {:ok, cast} =
      ProjectionsCrud.create_projection(%{module: "module-1", scope_uuid: uuid, seq: 1})

    assert cast.status == :new
  end

  test "prevents duplicate casts with same module" do
    uuid = Essig.UUID7.generate()

    {:ok, _cast} =
      ProjectionsCrud.create_projection(%{module: "module-1", scope_uuid: uuid, seq: 1})

    {:error, changeset} =
      ProjectionsCrud.create_projection(%{module: "module-1", scope_uuid: uuid, seq: 2})

    errors = errors_on(changeset)
    assert errors == %{scope_uuid: ["has already been taken"]}
  end

  test "allows updating the `max_id` value via upsert on (module)" do
    uuid = Essig.UUID7.generate()

    {:ok, cast} =
      ProjectionsCrud.create_projection(%{module: "module-1", scope_uuid: uuid, seq: 1})

    {:ok, cast2} =
      ProjectionsCrud.upsert_projection(%{
        module: "module-1",
        scope_uuid: uuid,
        max_id: 2,
        seq: 1,
        status: :backfilling
      })

    assert cast2.max_id == 2

    {:ok, cast3} =
      ProjectionsCrud.upsert_projection(%{
        module: "module-1",
        scope_uuid: uuid,
        seq: 5,
        max_id: 7,
        status: :backfilling
      })

    assert cast3.seq == 5
    assert cast3.max_id == 7
    # same DB record!
    assert cast.id == cast2.id
    assert cast.id == cast3.id
  end
end
