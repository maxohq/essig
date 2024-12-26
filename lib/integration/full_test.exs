defmodule Essig.Integration.FullTest do
  use ExUnit.Case, async: true
  import Liveness

  setup %{test: test_name} do
    Essig.Context.set_current_scope(test_name)
    start_supervised({Essig.Scopes.Server, test_name})
    :ok
  end

  describe "system setup" do
    # test "cast registry start / stop / de-registration works" do
    #   {:ok, cast1} = Casts.Cast1.start_link(1)
    #   {:ok, cast2} = Casts.Cast2.start_link(1)

    #   assert Essig.Casts.Registry.keys() |> Enum.count() == 2

    #   assert Essig.Casts.Registry.get(Casts.Cast1) == cast1
    #   assert Essig.Casts.Registry.get(Casts.Cast2) == cast2

    #   GenServer.stop(cast1)
    #   refute Process.alive?(cast1)
    #   assert eventually(fn -> Essig.Casts.Registry.keys() |> Enum.count() == 1 end)
    #   assert Essig.Casts.Registry.get(Casts.Cast1) == nil

    #   GenServer.stop(cast2)
    #   refute Process.alive?(cast2)
    #   assert eventually(fn -> Essig.Casts.Registry.keys() |> Enum.count() == 0 end)
    #   assert Essig.Casts.Registry.get(Casts.Cast2) == nil
    # end

    test "entity registry start / stop / de-registration works" do
      {:ok, entity1_1} = Entities.Entity1.start_link(uuid: "1")
      {:ok, entity1_2} = Entities.Entity1.start_link(uuid: "2")
      {:ok, entity2_1} = Entities.Entity2.start_link(uuid: "1")
      {:ok, entity2_2} = Entities.Entity2.start_link(uuid: "2")

      assert Essig.Entities.Registry.keys() |> Enum.count() == 4

      assert Essig.Entities.Registry.get(Entities.Entity1, "1") == entity1_1
      assert Essig.Entities.Registry.get(Entities.Entity1, "2") == entity1_2
      assert Essig.Entities.Registry.get(Entities.Entity2, "1") == entity2_1
      assert Essig.Entities.Registry.get(Entities.Entity2, "2") == entity2_2

      GenServer.stop(entity1_1)
      refute Process.alive?(entity1_1)
      assert eventually(fn -> Essig.Entities.Registry.keys() |> Enum.count() == 3 end)
      assert Essig.Entities.Registry.get(Entities.Entity1, "1") == nil

      GenServer.stop(entity2_1)
      refute Process.alive?(entity2_1)
      assert eventually(fn -> Essig.Entities.Registry.keys() |> Enum.count() == 2 end)
      assert Essig.Entities.Registry.get(Entities.Entity2, "1") == nil

      GenServer.stop(entity1_2)
      GenServer.stop(entity2_2)
      assert eventually(fn -> Essig.Entities.Registry.keys() |> Enum.count() == 0 end)

      # re-registration works fine
      {:ok, entity1_1} = Entities.Entity1.start_link(uuid: "1")
      assert Essig.Entities.Registry.keys() |> Enum.count() == 1
      assert Essig.Entities.Registry.get(Entities.Entity1, "1") == entity1_1
    end
  end
end
