defmodule SeqCheckerTest do
  use ExUnit.Case

  describe "check_reached/2" do
    setup do
      Context.set_current_app("app1")
      HandlerMeta.init()
      :ok
    end

    test "check if all given modules have at least reached the required SEQ value" do
      HandlerMeta.set(TestModule1, %{seq: 5})
      HandlerMeta.set(TestModule2, %{seq: 5})

      assert SeqChecker.check_reached([TestModule1, TestModule2], 5)
      refute SeqChecker.check_reached([TestModule1, TestModule2], 6)

      HandlerMeta.update(TestModule1, %{seq: 8})
      HandlerMeta.update(TestModule2, %{seq: 7})
      assert SeqChecker.check_reached([TestModule1, TestModule2], 6)
      assert SeqChecker.check_reached([TestModule1, TestModule2], 7)
      refute SeqChecker.check_reached([TestModule1, TestModule2], 8)
    end
  end
end
