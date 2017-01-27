defmodule InstaCrawler.Crawler do
  use GenStage
  alias InstaCrawler.{Gateway, Parser}

  @max_demand 100

  def start_link(session, parser) do
    GenStage.start_link(__MODULE__, [session, parser])
  end

  def init([session, parser]) do
    send(self(), :init)
    {:producer_consumer, %{session: session, parser: parser, parser_from: nil}}
  end

  def handle_events(events, _from, state) do
    %{session: session, parser: parser, parser_from: parser_from} = state

    new_events = events
    |> Flow.from_enumerable()
    |> Flow.partition()
    |> Flow.map(&{&1, Gateway.request(&1, session)})
    |> Flow.filter_map(fn {_, {status, _}} ->
        status == :ok
      end,
      fn {req, {_, resp}} ->
        {req, resp}
      end)
    |> Enum.reverse()

    Parser.parse(parser, new_events)
    GenStage.ask(parser_from, @max_demand)

    {:noreply, new_events, state}
  end

  def handle_subscribe(:producer, _opts, {pid, _} = from, %{parser: parser} = state) do
    case pid do
      ^parser ->
        GenStage.ask(from, @max_demand)
        {:manual, %{state | parser_from: from}}
      _ -> {:automatic, state}
    end
  end

  def handle_subscribe(:consumer, _opts, _from, state) do
    {:automatic, state}
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

  def handle_info(:init, %{parser: parser} = state) do
    GenStage.sync_subscribe(:storage, to: self())
    GenStage.async_subscribe(self(), to: parser)
    {:noreply, [], state}
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

  def start_child(session, parser) do
    Supervisor.start_child(__MODULE__, [session, parser])
  end

  def new(session, parser) do
    Cluster.start(__MODULE__, :start_child, [session, parser])
  end

  def init(:ok) do
    import Supervisor.Spec

    children = [
      worker(InstaCrawler.Crawler, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
