defmodule Essig.HandlerMetaTest do
  use ExUnit.Case, async: true
  require Logger

  defmodule HandlerMeta do
    use Essig.GenMetaTable, "handler_meta"
  end

  setup do
    # Set up a test app context
    scope_uuid = Essig.UUID7.generate()
    Essig.Context.set_current_scope(scope_uuid)

    on_exit(fn ->
      Essig.Context.set_current_scope(nil)
    end)

    %{scope_uuid: scope_uuid}
  end

  test "init/0 creates an ETS table", %{scope_uuid: scope_uuid} do
    HandlerMeta.init()
    assert :ets.info(String.to_atom("#{scope_uuid}_handler_meta")) != :undefined
  end

  test "repeated init/0 does not raise", %{scope_uuid: scope_uuid} do
    name = HandlerMeta.init()
    assert name == HandlerMeta.init()
    assert :ets.info(String.to_atom("#{scope_uuid}_handler_meta")) != :undefined
  end

  test "set/2 inserts data into the ETS table" do
    HandlerMeta.init()
    HandlerMeta.set(TestModule, %{field: "value"})
    assert HandlerMeta.get(TestModule) == %{field: "value", key: TestModule}
  end

  test "update/2 merges new data with existing data" do
    HandlerMeta.init()
    HandlerMeta.set(TestModule, %{key1: "value1"})
    HandlerMeta.update(TestModule, %{key2: "value2"})
    assert HandlerMeta.get(TestModule) == %{key1: "value1", key2: "value2", key: TestModule}
  end

  test "update/2 inserts data if module doesn't exist" do
    HandlerMeta.init()
    HandlerMeta.update(TestModule, %{field: "value"})
    assert HandlerMeta.get(TestModule) == %{field: "value", key: TestModule}
  end

  test "get/1 returns nil for non-existent module" do
    HandlerMeta.init()
    assert HandlerMeta.get(NonExistentModule) == nil
  end

  test "all/0 returns all entries in the ETS table" do
    HandlerMeta.init()
    HandlerMeta.set(TestModule1, %{key1: "value1"})
    HandlerMeta.set(TestModule2, %{key2: "value2"})

    all_entries = HandlerMeta.all()
    assert length(all_entries) == 2
    assert {TestModule1, %{key: TestModule1, key1: "value1"}} in all_entries
    assert {TestModule2, %{key: TestModule2, key2: "value2"}} in all_entries
  end

  test "delete_all/0 removes all entries from the ETS table" do
    HandlerMeta.init()
    HandlerMeta.set(TestModule1, %{key1: "value1"})
    HandlerMeta.set(TestModule2, %{key2: "value2"})

    HandlerMeta.delete_all()
    assert HandlerMeta.all() == []
  end

  test "delete/1 removes a specific entry from the ETS table" do
    HandlerMeta.init()
    HandlerMeta.set(TestModule1, %{key1: "value1"})
    HandlerMeta.set(TestModule2, %{key2: "value2"})

    HandlerMeta.delete(TestModule1)
    assert HandlerMeta.get(TestModule1) == nil
    assert HandlerMeta.get(TestModule2) == %{key2: "value2", key: TestModule2}
  end

  test "delete/1 does not raise an error when deleting a non-existent entry" do
    HandlerMeta.init()
    assert HandlerMeta.delete(NonExistentModule) == true
  end

  test "query/1 with OR condition" do
    HandlerMeta.init()
    HandlerMeta.set(TestModule1, %{status: :new})
    HandlerMeta.set(TestModule2, %{status: :idle})
    HandlerMeta.set(TestModule3, %{status: :backfilling})

    result = HandlerMeta.query(%{or: [[:=, :status, :new], [:=, :status, :backfilling]]})
    assert length(result) == 2

    assert Enum.any?(result, fn {module, data} ->
             module == TestModule1 and data.status == :new
           end)

    assert Enum.any?(result, fn {module, data} ->
             module == TestModule3 and data.status == :backfilling
           end)
  end

  test "query/1 with AND condition" do
    HandlerMeta.init()
    HandlerMeta.set(TestModule1, %{status: :ready, type: :handler})
    HandlerMeta.set(TestModule2, %{status: :ready, type: :projection})
    HandlerMeta.set(TestModule3, %{status: :new, type: :handler})

    result = HandlerMeta.query(%{and: [%{status: :ready}, %{type: :handler}]})
    assert length(result) == 1

    assert Enum.at(result, 0) ==
             {TestModule1, %{status: :ready, type: :handler, key: TestModule1}}
  end

  test "query/1 with implicit AND condition" do
    HandlerMeta.init()
    HandlerMeta.set(TestModule1, %{status: :ready})
    HandlerMeta.set(TestModule2, %{status: :new})

    result = HandlerMeta.query(%{status: :ready})
    assert length(result) == 1
    assert Enum.at(result, 0) == {TestModule1, %{status: :ready, key: TestModule1}}
  end

  test "query/1 with alternative syntax" do
    HandlerMeta.init()
    HandlerMeta.set(TestModule1, %{status: :new})
    HandlerMeta.set(TestModule2, %{status: :ready})

    result = HandlerMeta.query(%{and: [%{status: :new}]})
    assert length(result) == 1
    assert Enum.at(result, 0) == {TestModule1, %{status: :new, key: TestModule1}}
  end

  test "operations with different app contexts", %{scope_uuid: scope_uuid} do
    HandlerMeta.init()
    HandlerMeta.set(TestModule, %{field: "value1"})

    # Switch to a different app context
    Essig.Context.set_current_scope("another_app")
    HandlerMeta.init()
    HandlerMeta.set(TestModule, %{field: "value2"})

    assert HandlerMeta.get(TestModule) == %{field: "value2", key: TestModule}

    # Switch back to the original app context
    Essig.Context.set_current_scope(scope_uuid)
    assert HandlerMeta.get(TestModule) == %{field: "value1", key: TestModule}
  end
end
