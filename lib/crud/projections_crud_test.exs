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

    {:ok, projection} =
      ProjectionsCrud.create_projection(%{module: "module-1", scope_uuid: uuid, seq: 1})

    assert projection.status == :new
  end

  test "prevents duplicate projections with same module" do
    uuid = Essig.UUID7.generate()

    {:ok, _projection} =
      ProjectionsCrud.create_projection(%{module: "module-1", scope_uuid: uuid, seq: 1})

    {:error, changeset} =
      ProjectionsCrud.create_projection(%{module: "module-1", scope_uuid: uuid, seq: 2})

    errors = errors_on(changeset)
    assert errors == %{scope_uuid: ["has already been taken"]}
  end

  test "can be fetched by module name" do
    scope_uuid = Essig.UUID7.generate()
    Essig.Context.set_current_scope(scope_uuid)

    {:ok, projection} =
      ProjectionsCrud.create_projection(%{module: "Module1", scope_uuid: scope_uuid, seq: 1})

    copy = ProjectionsCrud.get_projection_by_module("Module1")

    assert copy == projection
  end

  test "updates work ok" do
    scope_uuid = Essig.UUID7.generate()
    Essig.Context.set_current_scope(scope_uuid)

    {:ok, p1} =
      ProjectionsCrud.create_projection(%{module: "Module1", scope_uuid: scope_uuid, seq: 1})

    {:ok, p2} = ProjectionsCrud.update_projection(p1, %{seq: 2, max_id: 5})
    assert p2.seq == 2
    assert p2.max_id == 5
    {:ok, p3} = ProjectionsCrud.update_projection(p2, %{seq: 3})
    assert p3.seq == 3
    {:ok, p4} = ProjectionsCrud.update_projection(p3, %{seq: 4, status: "idle"})
    assert p4.seq == 4
    assert p4.status == :idle
  end

  test "allows updating the `max_id` value via upsert on (module)" do
    uuid = Essig.UUID7.generate()

    {:ok, projection} =
      ProjectionsCrud.create_projection(%{module: "module-1", scope_uuid: uuid, seq: 1})

    {:ok, projection2} =
      ProjectionsCrud.upsert_projection(%{
        module: "module-1",
        scope_uuid: uuid,
        max_id: 2,
        seq: 1,
        status: :backfilling
      })

    assert projection2.max_id == 2

    {:ok, projection3} =
      ProjectionsCrud.upsert_projection(%{
        module: "module-1",
        scope_uuid: uuid,
        seq: 5,
        max_id: 7,
        status: :backfilling
      })

    assert projection3.seq == 5
    assert projection3.max_id == 7
    # same DB record!
    assert projection.id == projection2.id
    assert projection.id == projection3.id
  end
end
