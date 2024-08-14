defmodule SupernamedTest do
  use ExUnit.Case
  doctest Supernamed

  test "greets the world" do
    assert Supernamed.hello() == :world
  end
end
