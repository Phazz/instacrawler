defmodule InstaCrawler.Storage do
  require Logger
  use GenStage

  @max_demand 100

  @collection "content"

  def start_link(conn) do
    GenStage.start_link(__MODULE__, conn, name: :storage)
  end

  def init(conn) do
    {:consumer, conn}
  end

  def handle_events(elems, _from, conn) do
    Logger.info("[Storage] Saving #{length(elems)} elems")
    with values <- Enum.map(elems, &destruct/1),
      do: Mongo.insert_many(conn, @collection, values, continue_on_error: true)
    {:noreply, [], conn}
  end

  def destruct({parent, child}) do
    %{parent: Map.from_struct(parent), child: child}
  end

end
