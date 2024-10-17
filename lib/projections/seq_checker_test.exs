defmodule Essig.Projections.SeqCheckerTest do
  use ExUnit.Case, async: true
  alias Essig.Projections.SeqChecker

  describe "check_reached/2" do
    setup do
      Essig.Server.start_scope(Essig.UUID7.generate())
      # Essig.Context.set_current_scope("app1")
      # Essig.Projections.MetaTable.init()
      :ok
    end

    test "check if all given modules have at least reached the required SEQ value" do
      Essig.Projections.MetaTable.set(TestModule1, %{seq: 5})
      Essig.Projections.MetaTable.set(TestModule2, %{seq: 5})

      assert SeqChecker.check_reached([TestModule1, TestModule2], 5)
      refute SeqChecker.check_reached([TestModule1, TestModule2], 6)

      Essig.Projections.MetaTable.update(TestModule1, %{seq: 8})
      Essig.Projections.MetaTable.update(TestModule2, %{seq: 7})
      assert SeqChecker.check_reached([TestModule1, TestModule2], 6)
      assert SeqChecker.check_reached([TestModule1, TestModule2], 7)
      refute SeqChecker.check_reached([TestModule1, TestModule2], 8)
    end
  end
end
