defmodule InstaCrawler.Crawler do
  use GenServer
  alias InstaCrawler.{Client, Extractor, DistributedTask}

  @possible_ids [:pk, :id, :media_id, :profile_pic_id, :user_id, :username, :next_max_id, :max_id]

  def refresh_session(crawler, session) do
    GenServer.call(crawler, {:refresh, session})
  end

  def flush(crawler) do
    GenServer.call(crawler, :flush)
  end

  def crawl(crawler, entrypoint) do
    GenServer.cast(crawler, {nil, entrypoint})
  end

  def start_link(session, callback) do
    GenServer.start_link(__MODULE__, {session, callback})
  end

  def init({session, callback}) do
    {:ok, client} = Client.Supervisor.new(session)
    {:ok, {client, MapSet.new, callback}}
  end

  def handle_call({:refresh, session}, _from, {client, cache, callback} = state) do
    {:reply, Client.refresh_session(client, session), state}
  end
  def handle_call(:flush, _from, {client, cache, callback}) do
    {:reply, cache, {client, MapSet.new, callback}}
  end

  def handle_cast({parent_req, req} = rel, {client, cache, callback}) when is_tuple(req) do
    new_cache =  MapSet.put(cache, req)

    unless MapSet.member?(cache, req) do
      resp = Client.request(client, req)

      case resp do
        {:ok, result} ->
          callback.({:rel, rel})
          callback.({:value, {req, result}})
          DistributedTask.async_nolink(fn ->
            {req, Extractor.extract(result, @possible_ids)}
          end)
        {:err, error} ->
          callback.({:err, error})
      end
    else
      callback.({:rel, rel})
    end
    {:noreply, {client, new_cache, callback}}
  end

  def handle_info({_, {req, tokens}}, {_client, cache, _callback} = state) when is_list(tokens) do
    tokens
    |> Stream.flat_map(&to_requests(req, &1))
    |> Stream.dedup
    |> Stream.each(&GenServer.cast(self, {req, &1}))
    |> Stream.run
    {:noreply, state}
  end
  def handle_info({:DOWN, _, :process, _, _}, state) do
    {:noreply, state}
  end

  defp to_requests(req, {key, id}) do
    cond do
      key in [:pk, :user_id] ->
        [
          {:user_id, id, :followers},
          {:user_id, id, :following},
          {:user_id, id, :media_tags},
          {:user_id, id, :media}
        ]
      key in [:profile_pic_id, :id, :media_id] ->
        [
          {:media, id, :info},
          {:media, id, :comments},
          {:media, id, :likers}
        ]
      key in [:username] ->
        [
          {:username, id, :info}
        ]
      key in [:next_max_id, :max_id] ->
        [
          if tuple_size(req) > 3 do
            put_elem(req, 3, [max_id: id])
          else
            Tuple.append(req, [max_id: id])
          end
        ]
    end
  end
  defp to_requests(req, []), do: []

end

defmodule InstaCrawler.Crawler.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def new(session, callback) do
    Supervisor.start_child(__MODULE__, [session, callback])
  end

  def init(:ok) do
    children = [
      worker(InstaCrawler.Crawler, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
