defmodule InstaCrawler.Parser do
  use GenStage
  alias InstaCrawler.{Extractor, PrivateAPI.Request}

  @user_id_length 10

  @possible_keys [:pk, :id, :media_id, :profile_pic_id, :user_id, :external_id,
                 :username, :next_max_id, :max_id, :facebook_places_id, :location]

  def start_link(opts \\ []) do
    GenStage.start_link(__MODULE__, opts)
  end

  def init(opts) do
    keys = Keyword.get(opts, :keys, @possible_keys)
    {:producer_consumer, %{keys: keys}}
  end

  def handle_events(events, _from, state) do
    new_events = events
    |> Flow.from_enumerable
    |> Flow.flat_map(&handle_event(&1, state))
    |> Flow.uniq
    |> Enum.reverse
    {:noreply, new_events, state}
  end

  defp handle_event(event, %{keys: keys}) do
    case event do
      {:content, {req, result}} ->
        result
        |> Extractor.extract(keys)
        |> Stream.dedup
        |> Stream.flat_map(&to_requests(req, &1))
        |> Enum.map(& {req, &1})
      _ -> []
    end
  end

  def handle_info({from, :poison}, state) do
    {:stop, :normal, state}
  end


  defp to_requests(_req, {key, value}) when key in [:profile_pic_id, :id, :media_id] do
    [
      %Request{entity: :media, id: value, resource: :comments},
      %Request{entity: :media, id: value, resource: :info},
      %Request{entity: :media, id: value, resource: :likers}
    ]
  end
  defp to_requests(req, {:pk, value}) when is_binary(value) do
    to_requests(req, {:id, value})
  end
  defp to_requests(req, {:pk, value}) when is_number(value) do
    if :math.log10(value) < @user_id_length do
      to_requests(req, {:user_id, value})
    else
      to_requests(req, {:id, value})
    end
  end
  defp to_requests(_req, {:user_id, value}) do
    [
      %Request{entity: :user, id: value, resource: :media},
      %Request{entity: :user, id: value, resource: :followers},
      %Request{entity: :user, id: value, resource: :following},
      %Request{entity: :user, id: value, resource: :media_tags}
    ]
  end
  defp to_requests(_req, {key, value}) when key in [:external_id, :facebook_places_id] do
      [
        %Request{entity: :location, id: value, resource: :feed}
      ]
  end
  defp to_requests(_req, {:location, value}) do
      [
        %Request{
          entity: :location,
          id: value[:address],
          resource: :search,
          params: %{longitude: value[:lat], latitude: value[:lng]}
        }
      ]
  end
  defp to_requests(_req, {:username, value}) do
      [
        %Request{entity: :username, id: value, resource: :info}
      ]
  end
  defp to_requests(req, {key, value}) when key in [:next_max_id, :max_id] do
      [
        %{req | params: %{max_id: value}}
      ]
  end
  defp to_requests(_req, []), do: []

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
      worker(InstaCrawler.Parser, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
