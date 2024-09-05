defmodule Essig.EventStore.Cache do
  @moduledoc """
  Cache layer for the EventStore.

  - allows concurrent requests without work duplication and blocking

  Special notes:
  - we use a map to signify the state of the cache (usually this is an atom)
  - this map contains currently running cache misses
  - every change on this map triggers a state transition in gen_statem
  - the postponed requests get a chance to run again on each state transition
  """

  @behaviour :gen_statem

  defstruct busy: %{}, cache: %{}

  def start_link(opts \\ []), do: :gen_statem.start_link(__MODULE__, [], opts)

  @impl true
  def callback_mode(), do: [:handle_event_function, :state_enter]

  @impl true
  def init(_) do
    # state / data / actions
    {:ok, %{}, %__MODULE__{}, []}
  end

  ### PUBLIC API ###

  def request(pid, request), do: :gen_statem.call(pid, {:request, request})
  def get_state(pid), do: :gen_statem.call(pid, :get_state)

  ### INTERNAL ###

  @impl :gen_statem
  def handle_event(:enter, _before_state, _after_state, _data), do: {:keep_state_and_data, []}

  # just return state / data
  def handle_event({:call, from}, :get_state, state, data) do
    {:keep_state, data, [{:reply, from, {state, data}}]}
  end

  #
  def handle_event({:call, from}, {:request, request}, _, data) do
    res = get_from_cache(data, request)
    in_busy = is_busy_for_request(data, request)

    cond do
      # we have a result in cache, so we reply immediately
      res != nil ->
        actions = [{:reply, from, res}]
        {:keep_state_and_data, actions}

      # we are already busy with this request, so we postpone
      in_busy ->
        actions = [:postpone]
        {:keep_state_and_data, actions}

      # not in cache and no in-progress fetching, so we schedule a fetch
      true ->
        data = mark_busy_for_request(data, request, from)
        actions = [{:next_event, :internal, {:fetch_data, request, from}}]
        {:next_state, data.busy, data, actions}
    end
  end

  # fetch data and populate the cache
  def handle_event(:cast, {:set_response, request, response, from}, _state, data) do
    data = mark_done_for_request(data, request)
    data = store_in_cache(data, request, response)
    actions = [{:reply, from, response}]
    {:next_state, data.busy, data, actions}
  end

  def handle_event(:internal, {:fetch_data, {mod, fun, args} = request, from}, _s, _data) do
    pid = self()

    Task.start(fn ->
      response = apply(mod, fun, args)
      GenServer.cast(pid, {:set_response, request, response, from})
    end)

    {:keep_state_and_data, []}
  end

  defp is_busy_for_request(data, request) do
    Map.get(data.busy, request, false)
  end

  defp mark_busy_for_request(data, request, from) do
    %__MODULE__{data | busy: Map.put(data.busy, request, from)}
  end

  defp mark_done_for_request(data, request) do
    %__MODULE__{data | busy: Map.delete(data.busy, request)}
  end

  defp store_in_cache(data, request, res) do
    %__MODULE__{data | cache: Map.put(data.cache, request, res)}
  end

  defp get_from_cache(data, request) do
    Map.get(data.cache, request, nil)
  end
end
