defmodule Essig.ServerTest do
  use ExUnit.Case, async: true
  import Liveness

  describe "full_run" do
    test "works with casts" do
      Essig.Server.start_scope("app1")
      Essig.Server.start_casts([SampleCast1, SampleCast2])
      pid = Essig.Scopes.Registry.get("app1")
      assert is_pid(pid)
      assert "app1" in Essig.Scopes.Registry.keys()

      assert is_pid(Essig.Server.get_cast(SampleCast1))
      assert is_pid(Essig.Server.get_cast(SampleCast2))

      Process.flag(:trap_exit, true)
      GenServer.stop(pid)
      assert eventually(fn -> Essig.Scopes.Registry.get("app1") == nil end)

      assert_raise ArgumentError, "unknown registry: Essig.Casts.Registry_app1", fn ->
        is_pid(Essig.Server.get_cast(SampleCast1))
      end

      refute "app1" in Essig.Scopes.Registry.keys()
    end

    test "works with entities" do
      Essig.Server.start_scope("app1")
      {:ok, _} = Essig.Server.start_entity(Entities.Entity1, "1")

      # duplicate entities are prevented
      {:error, {:already_started, _}} = Essig.Server.start_entity(Entities.Entity1, "1")

      pid = Essig.Scopes.Registry.get("app1")
      assert is_pid(pid)

      assert "app1" in Essig.Scopes.Registry.keys()

      assert is_pid(Essig.Server.get_entity(Entities.Entity1, "1"))

      Process.flag(:trap_exit, true)
      GenServer.stop(pid)
      assert eventually(fn -> Essig.Scopes.Registry.get("app1") == nil end)

      assert_raise ArgumentError, "unknown registry: Essig.Entities.Registry_app1", fn ->
        is_pid(Essig.Server.get_entity(Entities.Entity1, "1"))
      end
    end
  end
end
