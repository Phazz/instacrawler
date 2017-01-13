defmodule InstaCrawler.Linker do
  use GenServer

  def link(linker, rel) do
    GenServer.cast(linker, {:link, rel})
  end

  def graph(linker) do
    GenServer.call(linker, :graph)
  end

  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    {:ok, :digraph.new}
  end

  def handle_cast({:link, rel}, graph) do
    handle_link(rel, graph)

    {:noreply, graph}
  end

  defp handle_link({first, second}, graph) do
    :digraph.add_vertex(graph, first)
    :digraph.add_vertex(graph, second)
    :digraph.add_edge(graph, first, second)
  end

  def handle_call(:graph, _from, graph) do
    copy = :digraph_utils.subgraph(graph, :digraph.vertices(graph))
    {:reply, copy, graph}
  end

end

defmodule InstaCrawler.Linker.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def new do
    Supervisor.start_child(__MODULE__, [])
  end

  def init(:ok) do
    children = [
      worker(InstaCrawler.Linker, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
