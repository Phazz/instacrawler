defmodule InstaCrawler.Gateway do
  use GenServer

  alias InstaCrawler.{PrivateAPI, DistributedTask, Cluster}

  def request({req, session}) do
    GenServer.call(__MODULE__, {req, session}, :infinity)
  end

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({req, session}, from, refs) do
    task = DistributedTask.async_nolink(fn ->
      {from, PrivateAPI.request(req, session)}
    end)

    refs = Map.put(refs, task.ref, {from, req})

    {:noreply, refs}
  end

  def handle_info({_, {from, response}}, refs) when is_tuple(from) do
    GenServer.reply(from, response)
    {:noreply, refs}
  end
  def handle_info({:DOWN, ref, :process, _, reason}, refs) do
    {{from, _req}, refs} = Map.pop(refs, ref)
    if reason != :normal do
      GenServer.reply(from, {:err, reason})
    end
    {:noreply, refs}
  end

end

defmodule InstaCrawler.Gateway.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      worker(InstaCrawler.Gateway, [], restart: :permanent)
    ]

    supervise(children, strategy: :one_for_one)
  end
end
