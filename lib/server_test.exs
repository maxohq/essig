defmodule Essig.ServerTest do
  use Essig.DataCase
  import Liveness

  describe "full_run" do
    test "works with projections" do
      scope_uuid = Essig.UUID7.generate()
      Essig.Server.start_scope(scope_uuid)
      Essig.Server.start_projections([SampleProjection1, SampleProjection2])
      pid = Essig.Scopes.Registry.get(scope_uuid)
      assert is_pid(pid)
      assert scope_uuid in Essig.Scopes.Registry.keys()

      assert is_pid(Essig.Server.get_projection(SampleProjection1))
      assert is_pid(Essig.Server.get_projection(SampleProjection2))

      Process.flag(:trap_exit, true)
      GenServer.stop(pid)
      assert eventually(fn -> Essig.Scopes.Registry.get(scope_uuid) == nil end)

      assert_raise ArgumentError,
                   "unknown registry: :\"Elixir.Essig.Projections.Registry_#{scope_uuid}\"",
                   fn ->
                     is_pid(Essig.Server.get_projection(SampleProjection1))
                   end

      refute scope_uuid in Essig.Scopes.Registry.keys()
    end

    test "works with entities" do
      scope_uuid = Essig.UUID7.generate()
      Essig.Server.start_scope(scope_uuid)
      {:ok, _} = Essig.Server.start_entity(Entities.Entity1, "1")

      # duplicate entities are prevented
      {:error, {:already_started, _}} = Essig.Server.start_entity(Entities.Entity1, "1")

      pid = Essig.Scopes.Registry.get(scope_uuid)
      assert is_pid(pid)

      assert scope_uuid in Essig.Scopes.Registry.keys()

      assert is_pid(Essig.Server.get_entity(Entities.Entity1, "1"))

      Process.flag(:trap_exit, true)
      GenServer.stop(pid)
      assert eventually(fn -> Essig.Scopes.Registry.get(scope_uuid) == nil end)

      assert_raise ArgumentError,
                   "unknown registry: :\"Elixir.Essig.Entities.Registry_#{scope_uuid}\"",
                   fn ->
                     is_pid(Essig.Server.get_entity(Entities.Entity1, "1"))
                   end
    end
  end
end
