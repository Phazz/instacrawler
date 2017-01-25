defmodule InstaCrawler.Crawler do
  use GenStage
  alias InstaCrawler.{Gateway, PrivateAPI.Request}

  @max_retries 2

  def start_link(session, opts) do
    GenStage.start_link(__MODULE__, [session, opts])
  end

  def init([session, opts]) do
    crawls = Keyword.get(opts, :max_crawls, 1000)
    GenStage.cast(self(), :refresh)
    {:producer_consumer, %{session: session, counter: crawls},
    dispatcher: GenStage.BroadcastDispatcher}
  end

  def request(req, session, retries \\ 0)  do
    resp = Gateway.request(req, session)

    case resp do
      {:ok, content} ->
        result = {:content, {req, content}}
        max_id = Map.get(content, :next_max_id)

        if max_id do
          next_req = %{req | params: Map.put(req.params, :max_id, max_id)}
          [result | request(next_req, session)]
        else
          [result]
        end
      {:err, _} ->
        if retries < @max_retries do
          request(req, session, retries + 1)
        else
          []
        end
      _ -> []
    end
  end

  def handle_events(events, _from, %{session: session, counter: counter} = state) do
    new_events = events
    |> Stream.map(&elem(&1, 1))
    |> Flow.from_enumerable()
    |> Flow.partition()
    |> Flow.flat_map(&request(&1, session))
    |> Enum.reverse()

    counter = counter - 1

    if counter == 0 do
      GenStage.sync_notify(self(), :poison)
      {:stop, :normal, %{}}
    else
      {:noreply, new_events, %{state | counter: counter}}
    end
  end

  def handle_call({:swarm, :begin_handoff}, _from, state) do
   {:reply, {:resume, state}, [], state}
  end

  def handle_cast({:swarm, :end_handoff, state}, _state) do
   {:noreply, [], state}
  end
  def handle_cast({:swarm, :resolve_conflict, _state}, state) do
   {:noreply, [], state}
  end
  def handle_cast(:refresh, %{session: session} = state) do
    {:ok, new_session} = Gateway.request(%Request{resource: :login}, session)
    {:noreply, [], %{state | session: new_session}}
  end

  def handle_info({:swarm, :die}, state) do
   {:stop, :shutdown, state}
  end
  def handle_info(_, state) do
    {:noreply, [], state}
  end

end

defmodule InstaCrawler.Crawler.Supervisor do
  use Supervisor
  alias InstaCrawler.Cluster

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_child(session, opts \\ []) do
    Supervisor.start_child(__MODULE__, [session, opts])
  end

  def new(session, opts \\ []) do
    Cluster.start(__MODULE__, :start_child, [session, opts])
  end

  def init(:ok) do
    import Supervisor.Spec

    children = [
      worker(InstaCrawler.Crawler, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
