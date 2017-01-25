defmodule InstaCrawler.Storage.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(Mongo, [[
        name: :mongo,
        hostname: Confex.get(:storage, :hostname),
        port: Confex.get(:storage, :port),
        username: Confex.get(:storage, :username),
        password: Confex.get(:storage, :password),
        database: Confex.get(:storage, :database)
      ]], restart: :permanent),
      worker(InstaCrawler.Storage, [:mongo], restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: InstaCrawler.Storage.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
