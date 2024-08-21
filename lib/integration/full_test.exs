defmodule Scoped.Integration.FullTest do
  use ExUnit.Case

  describe "system setup" do
    test "works" do
      Context.set_current_scope("app1")
      Scopes.Server.start_link("app1")
      Casts.Registry.register(Casts.Cast1, self())
    end
  end
end
