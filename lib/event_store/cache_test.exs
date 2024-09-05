defmodule Essig.EventStore.CacheTest do
  use Essig.DataCase
  alias Essig.EventStore.Cache

  defmodule ReqBackend do
    def fetch(request) do
      Process.sleep(20)
      "RESULT: #{inspect(request)}"
    end
  end

  def req_tuple(value) do
    {ReqBackend, :fetch, [value]}
  end

  describe "full run" do
    test "multiple tasks with same request get the same result" do
      {:ok, pid} = Cache.start_link([])
      assert is_pid(pid)

      tasks =
        for _ <- 1..5 do
          Task.async(fn ->
            Cache.request(pid, req_tuple(1))
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
            Cache.request(pid, req_tuple(:rand.uniform(3)))
          end)
        end

      fetch_tasks =
        for _ <- 1..5 do
          Task.async(fn ->
            Cache.request(pid, req_tuple(1))
            Cache.request(pid, req_tuple(2))
            Cache.request(pid, req_tuple(3))
          end)
        end

      Task.await_many(pop_tasks ++ fetch_tasks)

      assert Cache.request(pid, req_tuple(1)) == "RESULT: 1"
      state = Cache.get_state(pid)

      assert state ==
               {%{},
                %Essig.EventStore.Cache{
                  busy: %{},
                  cache: %{
                    {Essig.EventStore.CacheTest.ReqBackend, :fetch, [1]} => "RESULT: 1",
                    {Essig.EventStore.CacheTest.ReqBackend, :fetch, [2]} => "RESULT: 2",
                    {Essig.EventStore.CacheTest.ReqBackend, :fetch, [3]} => "RESULT: 3"
                  }
                }}
    end
  end
end
