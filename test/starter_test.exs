defmodule StarterTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog
  require Logger
  import Liveness

  # remove noisy logs!
  @moduletag capture_log: true

  setup do
    # Set up a test app context
    test_app = "test_app_#{:rand.uniform(1000)}"
    Context.set_current_app(test_app)

    on_exit(fn ->
      # Clean up after each test
      Starter.stop_supervisor()
      Context.set_current_app(nil)
    end)

    %{test_app: test_app}
  end

  test "supervisor_name/0 returns the correct atom", %{test_app: test_app} do
    assert Starter.supervisor_name() == String.to_atom("#{test_app}_Supervisor")
  end

  test "ensure_supervisor_running/0 starts the supervisor" do
    assert Process.whereis(Starter.supervisor_name()) == nil
    Starter.add_modules([])
    assert Process.whereis(Starter.supervisor_name()) != nil
  end

  test "add_modules/1 starts child processes", %{test_app: test_app} do
    Starter.add_modules([Children.Child1, Children.Child2])

    assert Process.alive?(ChildRegistry.get(Children.Child1))
    assert Process.alive?(ChildRegistry.get(Children.Child2))

    children = Supervisor.which_children(Starter.supervisor_name())

    assert Enum.any?(children, fn
             {{^test_app, Children.Child1}, _, _, _} -> true
             _ -> false
           end)

    assert Enum.any?(children, fn
             {{^test_app, Children.Child2}, _, _, _} -> true
             _ -> false
           end)
  end

  test "remove_modules/1 stops and removes child processes", %{test_app: test_app} do
    Starter.add_modules([Children.Child1, Children.Child2])
    assert Process.alive?(ChildRegistry.get(Children.Child1))
    assert Process.alive?(ChildRegistry.get(Children.Child2))

    Starter.remove_modules([Children.Child1, Children.Child2])

    assert eventually(fn -> ChildRegistry.get(Children.Child1) == nil end)
    assert eventually(fn -> ChildRegistry.get(Children.Child2) == nil end)

    children = Supervisor.which_children(Starter.supervisor_name())

    refute Enum.any?(children, fn
             {{^test_app, Children.Child1}, _, _, _} -> true
             _ -> false
           end)

    refute Enum.any?(children, fn
             {{^test_app, Children.Child2}, _, _, _} -> true
             _ -> false
           end)
  end

  test "stop_supervisor/0 stops the supervisor" do
    Starter.add_modules([])
    assert Process.whereis(Starter.supervisor_name()) != nil

    Starter.stop_supervisor()
    assert Process.whereis(Starter.supervisor_name()) == nil
  end

  test "add_modules/1 logs when child is already started" do
    Starter.add_modules([Children.Child1])

    log =
      capture_log(fn ->
        Starter.add_modules([Children.Child1])
      end)

    assert log =~ "Child already running: {\"test_app_"
    assert log =~ ", Children.Child1}"
  end

  test "remove_modules/1 logs when child is not found" do
    Starter.add_modules([])

    log =
      capture_log(fn ->
        Starter.remove_modules([Children.Child1])
      end)

    assert log =~ "Child not found: {\"test_app_"
    assert log =~ ", Children.Child1}"
  end

  test "add_modules/1 and remove_modules/1 with multiple modules" do
    Starter.add_modules([Children.Child1, Children.Child2])

    assert Process.alive?(ChildRegistry.get(Children.Child1))
    assert Process.alive?(ChildRegistry.get(Children.Child2))

    Starter.remove_modules([Children.Child1])

    assert eventually(fn -> ChildRegistry.get(Children.Child1) == nil end)
    assert Process.alive?(ChildRegistry.get(Children.Child2))

    Starter.remove_modules([Children.Child2])

    assert ChildRegistry.get(Children.Child1) == nil
    assert eventually(fn -> ChildRegistry.get(Children.Child2) == nil end)
  end

  test "ensure_supervisor_running/0 logs error when no current app is set" do
    Context.set_current_app(nil)

    log =
      capture_log(fn ->
        Starter.add_modules([])
      end)

    assert log =~ "Set the current app via Context.set_current_app()!"
  end
end
