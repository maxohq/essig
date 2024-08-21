defmodule EsServerTest do
  use ExUnit.Case, async: true
  import Liveness

  describe "full_run" do
    test "works with casts" do
      EsServer.start_scope("app1")
      EsServer.start_casts([Casts.Cast1, Casts.Cast2])
      pid = Scopes.Registry.get("app1")
      assert is_pid(pid)
      assert "app1" in Scopes.Registry.keys()

      assert is_pid(EsServer.get_cast(Casts.Cast1))
      assert is_pid(EsServer.get_cast(Casts.Cast2))

      Process.flag(:trap_exit, true)
      GenServer.stop(pid)
      assert eventually(fn -> Scopes.Registry.get("app1") == nil end)

      assert_raise ArgumentError, "unknown registry: Casts.Registry_app1", fn ->
        is_pid(EsServer.get_cast(Casts.Cast1))
      end

      refute "app1" in Scopes.Registry.keys()
    end

    test "works with entities" do
      EsServer.start_scope("app1")
      EsServer.start_entity(Entities.Entity1, "1")
      pid = Scopes.Registry.get("app1")
      assert is_pid(pid)

      assert "app1" in Scopes.Registry.keys()

      assert is_pid(EsServer.get_entity(Entities.Entity1, "1"))

      Process.flag(:trap_exit, true)
      GenServer.stop(pid)
      assert eventually(fn -> Scopes.Registry.get("app1") == nil end)

      assert_raise ArgumentError, "unknown registry: Entities.Registry_app1", fn ->
        is_pid(EsServer.get_entity(Entities.Entity1, "1"))
      end
    end
  end
end
