defmodule Essig.CacheTest do
  use Essig.DataCase
  alias Essig.Cache

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

      tasks =
        for _ <- 1..5 do
          Task.async(fn ->
            Cache.request(pid, req_tuple(1))
          end)
        end

      results = Task.await_many(tasks)

      assert length(results) == 5
      [first_result | rest] = results
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
      state = clean_state(pid)

      assert state ==
               %Essig.Cache{
                 busy: %{},
                 cache: %{
                   {Essig.CacheTest.ReqBackend, :fetch, [1]} => "RESULT: 1",
                   {Essig.CacheTest.ReqBackend, :fetch, [2]} => "RESULT: 2",
                   {Essig.CacheTest.ReqBackend, :fetch, [3]} => "RESULT: 3"
                 },
                 expire_in: %{
                   {Essig.CacheTest.ReqBackend, :fetch, [1]} => 30000,
                   {Essig.CacheTest.ReqBackend, :fetch, [2]} => 30000,
                   {Essig.CacheTest.ReqBackend, :fetch, [3]} => 30000
                 }
               }
    end
  end

  describe "remove_cache" do
    test "works" do
      {:ok, pid} = Cache.start_link([])
      Cache.request(pid, req_tuple(1))
      Cache.request(pid, req_tuple(2))
      Cache.remove(pid, req_tuple(1))

      assert clean_state(pid) == %Essig.Cache{
               busy: %{},
               expire_in: %{
                 {Essig.CacheTest.ReqBackend, :fetch, [2]} => 30000
               },
               cache: %{{Essig.CacheTest.ReqBackend, :fetch, [2]} => "RESULT: 2"}
             }
    end
  end

  describe "remove_expired" do
    test "works" do
      {:ok, pid} = Cache.start_link([])

      Cache.request(pid, req_tuple(1), expire_in: :timer.seconds(5))
      Cache.request(pid, req_tuple(2), expire_in: :timer.seconds(10))
      Cache.request(pid, req_tuple(3), expire_in: :timer.seconds(15))
      # default expire_in - 30 seconds
      Cache.request(pid, req_tuple(4))

      now = :erlang.monotonic_time()

      data = Cache.get_state(pid)
      time_factor = 1_000_000

      data1 = Cache.remove_expired_entries(data, now + :timer.seconds(5) * time_factor)

      assert data1.cache == %{
               {Essig.CacheTest.ReqBackend, :fetch, [2]} => "RESULT: 2",
               {Essig.CacheTest.ReqBackend, :fetch, [3]} => "RESULT: 3",
               {Essig.CacheTest.ReqBackend, :fetch, [4]} => "RESULT: 4"
             }

      data2 = Cache.remove_expired_entries(data, now + :timer.seconds(10) * time_factor)

      assert data2.cache == %{
               {Essig.CacheTest.ReqBackend, :fetch, [3]} => "RESULT: 3",
               {Essig.CacheTest.ReqBackend, :fetch, [4]} => "RESULT: 4"
             }

      data3 = Cache.remove_expired_entries(data, now + :timer.seconds(15) * time_factor)

      assert data3.cache == %{
               {Essig.CacheTest.ReqBackend, :fetch, [4]} => "RESULT: 4"
             }

      data4 = Cache.remove_expired_entries(data, now + :timer.seconds(30) * time_factor)

      assert data4.cache == %{}
    end
  end

  def clean_state(pid) do
    Cache.get_state(pid) |> Map.put(:valid_until, %{})
  end
end
