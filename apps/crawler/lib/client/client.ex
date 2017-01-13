defmodule InstaCrawler.Client do
  use GenServer

  alias InstaCrawler.Gateway

  @timeout Application.get_env(:crawler, :client_timeout, 30000)

  def request(client, req) do
    GenServer.call(client, {:request, req}, @timeout)
  end

  def refresh_session(client, session) do
    GenServer.call(client, {:refresh, session})
  end

  def start_link(session) do
    GenServer.start_link(__MODULE__, session)
  end

  def init(session) do
    {:ok, login(session)}
  end

  def handle_call({:request, req}, _from, session) do
    resp = Gateway.request({req, session})
    {:reply, resp, session}
  end
  def handle_call({:refresh, session}, _from, _session) do
    {:reply, session, login(session)}
  end
  def handle_call({:swarm, :begin_handoff}, _from, session) do
    {:reply, {:resume, session}, session}
  end

  def handle_cast({:swarm, :end_handoff, session}, _) do
    {:noreply, session}
  end

  defp login(session) do
    {:ok, cookies} = Gateway.request({:login, session})
    %{session | cookies: cookies}
  end

end

defmodule InstaCrawler.Client.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def new(session) do
    Supervisor.start_child(__MODULE__, [session])
  end

  def init(:ok) do
    children = [
      worker(InstaCrawler.Client, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
