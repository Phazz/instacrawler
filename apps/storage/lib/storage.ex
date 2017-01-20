defmodule InstaCrawler.Storage do
  use GenStage

  def start_link(conn) do
    GenStage.start_link(__MODULE__, conn, name: :storage)
  end

  def init(conn) do
    {:consumer, conn}
  end

  def handle_events(events, _from, conn) do
    for {coll, values} <- group(events) do
      conn |> Mongo.insert_many(coll, values, continue_on_error: true)
    end
    {:noreply, [], conn}
  end

  def handle_info({_from, _msg}, conn) do
    {:noreply, [], conn}
  end

  def group(events) do
    events
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Enum.map(fn {key, values} ->
      {Atom.to_string(key), Enum.map(values, &(transform/1))}
    end)
  end

  def transform({parent, child}) when is_map(parent) and is_map(child) do
    %{parent: stom(parent), child: stom(child)}
  end

  def stom(struct) do
    Map.delete(struct, :__struct__)
  end
end
