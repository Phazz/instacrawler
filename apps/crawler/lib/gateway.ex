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
    state = %{refs: %{}, cache: MapSet.new}
    {:ok, state}
  end

  def handle_call({req, session}, from, %{refs: refs, cache: cache} = state) do
    if MapSet.member?(cache, req) do
      {:reply, :noop, state}
    else
      task = DistributedTask.async_nolink(fn ->
        {from, PrivateAPI.request(req, session)}
      end)

      Logger.info("[#{inspect self()}] request: #{inspect req}")
      Logger.debug("[#{inspect self()}] session: #{inspect session}")

      updated_cache = MapSet.put(cache, req)

      updated_refs = Map.put(refs, task.ref, from)

      {:noreply, %{refs: updated_refs, cache: updated_cache}}
    end
  end

  def handle_info({_, {from, response}}, state) when is_tuple(from) do
    GenServer.reply(from, response)
    {:noreply, state}
  end
  def handle_info({:DOWN, ref, :process, _pid, reason}, %{refs: refs} = state) do
      {from, updated_refs} = Map.pop(refs, ref)
      if reason != :normal do
        GenServer.reply(from, {:err, %{reason: inspect(reason)}})
      end
      {:noreply, %{state | refs: updated_refs}}
  end


end
