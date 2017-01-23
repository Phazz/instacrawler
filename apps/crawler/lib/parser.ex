defmodule InstaCrawler.Parser do
  use GenStage
  alias InstaCrawler.{Extractor, PrivateAPI.Request}

  @user_id_length 10

  @possible_keys [:user_id, :pk, :id, :username, :media_id, :external_id,
                 :next_max_id, :max_id, :facebook_places_id, :location, :profile_pic_id]

  def start_link(opts \\ []) do
    GenStage.start_link(__MODULE__, opts)
  end

  def init(opts) do
    keys = Keyword.get(opts, :keys, @possible_keys)
    default_params = Keyword.get(opts, :default_params, %{})
    {:producer_consumer, %{keys: keys, params: default_params}}
  end

  def handle_events(events, _from, state) do
    new_events = events
    |> Flow.from_enumerable
    |> Flow.flat_map(&handle_event(&1, state))
    |> Enum.reverse
    {:noreply, new_events, state}
  end

  defp handle_event(event, %{keys: keys, params: params}) do
    case event do
      {:content, {req, result}} ->
        result
        |> Extractor.extract(keys)
        |> Enum.flat_map(&to_requests(req, &1, params))
        |> Enum.map(& {req, &1})
      _ -> []
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

  def handle_info({:swarm, :die}, state) do
    {:stop, :shutdown, state}
  end
  def handle_info({_from, :poison}, state) do
    {:stop, :normal, state}
  end


  defp to_requests(_req, {key, value}, _params) when key in [:profile_pic_id, :id, :media_id] do
    [
#      %Request{entity: :media, id: value, resource: :comments},
#      %Request{entity: :media, id: value, resource: :info},
#      %Request{entity: :media, id: value, resource: :likers}
    ]
  end
  defp to_requests(req, {:pk, value}, params) when is_binary(value) do
    to_requests(req, {:id, value}, params)
  end
  defp to_requests(req, {:pk, value}, params) when is_number(value) do
    if :math.log10(value) <= @user_id_length do
      to_requests(req, {:user_id, value}, params)
    else
      to_requests(req, {:id, value}, params)
    end
  end
  defp to_requests(_req, {:user_id, value}, params) do
    [
      %Request{entity: :user, id: value, resource: :media, params: params},
      %Request{entity: :user, id: value, resource: :followers},
      %Request{entity: :user, id: value, resource: :following},
#      %Request{entity: :user, id: value, resource: :media_tags}
    ]
  end
  defp to_requests(_req, {key, value}, params) when key in [:external_id, :facebook_places_id] do
      [
        %Request{entity: :location, id: value, resource: :feed, params: params}
      ]
  end
  defp to_requests(_req, {:location, value}, _params) do
      [
        %Request{
          entity: :location,
          id: value[:address],
          resource: :search,
          params: %{longitude: value[:lat], latitude: value[:lng]}
        }
      ]
  end
  defp to_requests(_req, {:username, value}, _params) do
      [
        %Request{entity: :username, id: value, resource: :info}
      ]
  end
  defp to_requests(req, {:next_max_id, value}, params) do
      [
        %{req | params: Map.put(params, :max_id, value)}
      ]
  end
  defp to_requests(_req, [], _params), do: []

end

defmodule InstaCrawler.Parser.Supervisor do
  use Supervisor
  alias InstaCrawler.Cluster

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_child(opts \\ []) do
    Supervisor.start_child(__MODULE__, [opts])
  end

  def new(opts \\ []) do
    Cluster.start(__MODULE__, :start_child, [opts])
  end

  def init(:ok) do
    import Supervisor.Spec

    children = [
      worker(InstaCrawler.Parser, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
