defmodule InstaCrawler.Crawler do
  require Logger
  use GenStage
  alias InstaCrawler.{Gateway, PrivateAPI.Request}

  def start_link(session, opts) do
    GenStage.start_link(__MODULE__, [session, opts])
  end

  def init([session, opts]) do
    crawls = Keyword.get(opts, :crawls, 1000)
    GenStage.cast(self(), :refresh)
    {:producer_consumer, %{session: session, counter: crawls},
    dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_events(events, _from, %{session: session, counter: counter} = state) do
    new_events = events
    |> Flow.from_enumerable
    |> Flow.flat_map(fn rel ->
      {_, req} = rel

      resp = Gateway.request(req, session)

      case resp do
        {:ok, content} ->
          [{:relation, rel}, {:content, {req, content}}]
        {:err, error} ->
          [{:error, {req, error}}]
        :noop -> []
      end
    end)
    |> Enum.reverse

    counter = counter - 1

    if counter == 0 do
      GenStage.async_notify(self(), :poison)
      {:stop, :normal, %{}}
    else
      {:noreply, new_events, %{state | counter: counter - 1}}
    end
  end

  def handle_cast(:refresh, %{session: session} = state) do
    {:ok, new_session} = Gateway.request(%Request{resource: :login}, session)
    {:noreply, [], %{state | session: new_session}}
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
