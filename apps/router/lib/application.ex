defmodule InstaCrawler.Router.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    port = Application.fetch_env!(:router, :port)

    children = [
       Plug.Adapters.Cowboy.child_spec(:http, InstaCrawler.Router, [], [port: port])
    ]

    opts = [strategy: :one_for_one, name: InstaCrawler.Router.Supervisor]
    Supervisor.start_link(children, opts)
  end
  
end
