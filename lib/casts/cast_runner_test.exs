defmodule Essig.Casts.CastRunnerTest do
  use ExUnit.Case, async: true
  alias Essig.Casts.CastRunner
  alias Essig.Casts.MetaTable

  setup %{test: test_name} do
    Essig.Server.start_scope(test_name)
    :ok
  end

  describe "start_link/1" do
    test "starts a CastRunner process for a given module" do
      assert [{:ok, _}, {:ok, _}] = Essig.Server.start_casts([SampleCast1, SampleCast2])
    end
  end

  describe "send_events/2" do
    setup do
      Essig.Server.start_casts([SampleCast1, SampleCast2])
      :ok
    end

    test "sends events to the specified CastRunner" do
      events = [%{id: 10, a: 1}, %{id: 100, b: 2}]

      CastRunner.send_events(SampleCast1, events)
      CastRunner.send_events(SampleCast2, events)

      # Assert that the events were processed by the respective CastRunners
      assert MetaTable.get(SampleCast1) == %{
               key: SampleCast1,
               module: SampleCast1,
               max_id: 100,
               seq: 2
             }

      assert MetaTable.get(SampleCast2) == %{
               key: SampleCast2,
               module: SampleCast2,
               max_id: 100,
               seq: 2
             }
    end
  end

  describe "metadata" do
    setup do
      Essig.Server.start_casts([SampleCast1, SampleCast2])
      :ok
    end

    test "stores metadata for each CastRunner" do
      # Assuming the metadata is updated when events are processed
      events = [%{id: 10, a: 1}, %{id: 100, b: 2}]
      CastRunner.send_events(SampleCast1, events)
      CastRunner.send_events(SampleCast2, events)
      CastRunner.send_events(SampleCast2, events)

      # # Assert the metadata for each CastRunner
      assert MetaTable.get(SampleCast1) == %{
               key: SampleCast1,
               module: SampleCast1,
               max_id: 100,
               seq: 2
             }

      assert MetaTable.get(SampleCast2) == %{
               key: SampleCast2,
               module: SampleCast2,
               max_id: 100,
               seq: 4
             }
    end
  end
end
