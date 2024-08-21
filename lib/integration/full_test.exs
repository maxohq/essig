defmodule Scoped.Integration.FullTest do
  use ExUnit.Case
  import Liveness

  describe "system setup" do
    test "cast registry start / stop / de-registration works", %{test: test_name} do
      Context.set_current_scope(test_name)

      start_supervised({Scopes.Server, test_name})
      {:ok, cast1} = Casts.Cast1.start_link(1)
      {:ok, cast2} = Casts.Cast2.start_link(1)

      assert Casts.Registry.keys() |> Enum.count() == 2

      assert Casts.Registry.get(Casts.Cast1) == cast1
      assert Casts.Registry.get(Casts.Cast2) == cast2

      GenServer.stop(cast1)
      refute Process.alive?(cast1)
      assert eventually(fn -> Casts.Registry.keys() |> Enum.count() == 1 end)
      assert Casts.Registry.get(Casts.Cast1) == nil

      GenServer.stop(cast2)
      refute Process.alive?(cast2)
      assert eventually(fn -> Casts.Registry.keys() |> Enum.count() == 0 end)
      assert Casts.Registry.get(Casts.Cast2) == nil
    end

    test "entity registry start / stop / de-registration works", %{test: test_name} do
      Context.set_current_scope(test_name)

      start_supervised({Scopes.Server, test_name})
      {:ok, entity1_1} = Entities.Entity1.start_link(uuid: "1")
      {:ok, entity1_2} = Entities.Entity1.start_link(uuid: "2")
      {:ok, entity2_1} = Entities.Entity2.start_link(uuid: "1")
      {:ok, entity2_2} = Entities.Entity2.start_link(uuid: "2")

      assert Entities.Registry.keys() |> Enum.count() == 4

      assert Entities.Registry.get(Entities.Entity1, "1") == entity1_1
      assert Entities.Registry.get(Entities.Entity1, "2") == entity1_2
      assert Entities.Registry.get(Entities.Entity2, "1") == entity2_1
      assert Entities.Registry.get(Entities.Entity2, "2") == entity2_2

      GenServer.stop(entity1_1)
      refute Process.alive?(entity1_1)
      assert eventually(fn -> Entities.Registry.keys() |> Enum.count() == 3 end)
      assert Entities.Registry.get(Entities.Entity1, "1") == nil

      GenServer.stop(entity2_1)
      refute Process.alive?(entity2_1)
      assert eventually(fn -> Entities.Registry.keys() |> Enum.count() == 2 end)
      assert Entities.Registry.get(Entities.Entity2, "1") == nil

      GenServer.stop(entity1_2)
      GenServer.stop(entity2_2)
      assert eventually(fn -> Entities.Registry.keys() |> Enum.count() == 0 end)
    end
  end
end
