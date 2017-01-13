defmodule InstaCrawler.PrivateAPI.Application do
  use Application

  def start(_type, _opts) do
    import Supervisor.Spec

    children = [
      worker(InstaCrawler.PrivateAPI.ProxyProvider, [])
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
