defmodule InstaCrawler.Gateway do
  require Logger
  use GenServer

  alias InstaCrawler.{PrivateAPI, DistributedTask}

  @gateway_timeout Application.get_env(:crawler, :gateway_timeout, 60_000)

  def request(req, session) do
    GenServer.call(:gateway, {req, session}, @gateway_timeout)
  end

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: :gateway)
  end

  def init(:ok) do
    state = %{refs: %{}, cache: %{}}
    {:ok, state}
  end

  def handle_call({req, session}, {pid, _} = from, %{refs: refs, cache: cache} = state) do
    reqs = Map.get(cache, pid, MapSet.new)

    if MapSet.size(reqs) == 0 do
      Process.monitor(pid)
    end

    if MapSet.member?(reqs, req) do
      {:reply, :noop, state}
    else
      task = DistributedTask.async_nolink(fn ->
        {from, PrivateAPI.request(req, session)}
      end)

      Logger.info("[#{inspect self()}] request: #{inspect req}")
      Logger.debug("[#{inspect self()}] session: #{inspect session}")

      updated_cache = Map.put(cache, pid, MapSet.put(reqs, req))

      updated_refs = Map.put(refs, task.ref, from)

      {:noreply, %{refs: updated_refs, cache: updated_cache}}
    end
  end

  def handle_info({_, {from, response}}, state) when is_tuple(from) do
    GenServer.reply(from, response)
    {:noreply, state}
  end
  def handle_info({:DOWN, ref, :process, pid, reason}, %{refs: refs, cache: cache} = state) do
    cond do
    Map.has_key?(refs, ref) ->
      {from, updated_refs} = Map.pop(refs, ref)
      if reason != :normal do
        GenServer.reply(from, {:err, %{}})
      end
      {:noreply, %{state | refs: updated_refs}}
    Map.has_key?(cache, pid) ->
      updated_cache = Map.delete(cache, pid)
      {:noreply, %{state | cache: updated_cache}}
    end
  end


end
