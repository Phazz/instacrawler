defmodule InstaCrawler.Crawler.Application do
  use Application

  def start(_type, _opts) do
    import Supervisor.Spec

    children = [
      supervisor(InstaCrawler.DistributedTask, []),
      worker(InstaCrawler.Gateway, [], restart: :permanent),
      supervisor(InstaCrawler.Crawler.Supervisor, []),
      supervisor(InstaCrawler.Parser.Supervisor, [])
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

end
