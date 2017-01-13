defmodule InstaCrawler.Crawler.Application do
  use Application

  def start(_type, _opts) do
    import Supervisor.Spec

    children = [
      #Plug.Adapters.Cowboy.child_spec(:http, InstaCrawler.Router, [], [port: Application.fetch_env!(:crawler, :cowboy_port)]),
      supervisor(InstaCrawler.DistributedTask, []),
      supervisor(InstaCrawler.Gateway.Supervisor, []),
      supervisor(InstaCrawler.Client.Supervisor, []),
      supervisor(InstaCrawler.Crawler.Supervisor, []),
      supervisor(InstaCrawler.Linker.Supervisor,[])
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

end
