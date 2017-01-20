defmodule InstaCrawler.Storage.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(Mongo, [[
        name: :mongo,
        hostname: Application.fetch_env!(:storage, :hostname),
        port: Application.fetch_env!(:storage, :port),
        username: Application.get_env(:storage, :username),
        password: Application.get_env(:storage, :password),
        database: Application.fetch_env!(:storage, :database)
      ]]),
      worker(InstaCrawler.Storage, [:mongo], restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: InstaCrawler.Storage.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
