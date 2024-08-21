defmodule Casts.SeqCheckerTest do
  use ExUnit.Case
  alias Casts.SeqChecker

  describe "check_reached/2" do
    setup do
      Context.set_current_scope("app1")
      Casts.MetaTable.init()
      :ok
    end

    test "check if all given modules have at least reached the required SEQ value" do
      Casts.MetaTable.set(TestModule1, %{seq: 5})
      Casts.MetaTable.set(TestModule2, %{seq: 5})

      assert SeqChecker.check_reached([TestModule1, TestModule2], 5)
      refute SeqChecker.check_reached([TestModule1, TestModule2], 6)

      Casts.MetaTable.update(TestModule1, %{seq: 8})
      Casts.MetaTable.update(TestModule2, %{seq: 7})
      assert SeqChecker.check_reached([TestModule1, TestModule2], 6)
      assert SeqChecker.check_reached([TestModule1, TestModule2], 7)
      refute SeqChecker.check_reached([TestModule1, TestModule2], 8)
    end
  end
end
