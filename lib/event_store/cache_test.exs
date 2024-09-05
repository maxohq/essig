defmodule Essig.EventStore.CacheTest do
  use Essig.DataCase
  alias Essig.EventStore.Cache

  describe "full run" do
    test "multiple tasks with same request get the same result" do
      {:ok, pid} = Cache.start_link([])
      assert is_pid(pid)

      tasks =
        for _ <- 1..5 do
          Task.async(fn ->
            Cache.request(pid, {:a, 1})
          end)
        end

      results = Task.await_many(tasks)

      assert length(results) == 5
      [first_result | rest] = results
      # IO.inspect(first_result)
      assert Enum.all?(rest, &(&1 == first_result))
    end

    test "multiple tasks with different requests work fine" do
      {:ok, pid} = Cache.start_link([])

      # we populate the cache
      pop_tasks =
        for _ <- 1..10 do
          Task.async(fn ->
            Cache.request(pid, {:a, :rand.uniform(3)})
          end)
        end

      fetch_tasks =
        for _ <- 1..5 do
          Task.async(fn ->
            Cache.request(pid, {:a, 1})
            Cache.request(pid, {:a, 2})
            Cache.request(pid, {:a, 3})
          end)
        end

      Task.await_many(pop_tasks ++ fetch_tasks)

      assert Cache.request(pid, {:a, 1}) == "RESULT: {:a, 1}"
      state = Cache.get_state(pid)

      assert state ==
               {%{},
                %Essig.EventStore.Cache{
                  busy: %{},
                  cache: %{
                    {:a, 1} => "RESULT: {:a, 1}",
                    {:a, 2} => "RESULT: {:a, 2}",
                    {:a, 3} => "RESULT: {:a, 3}"
                  }
                }}
    end
  end
end
