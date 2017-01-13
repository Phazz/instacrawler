defmodule InstaCrawler.Cluster do

  def start_link(mod, fun, args \\ []) do
    Swarm.register_name(UUID.uuid1(), mod, fun, args)
  end

  def register(pid) do
    Swarm.register_name(UUID.uuid1(), pid)
  end

end
