defmodule InstaCrawler.Crawler.Mixfile do
  use Mix.Project

  def project do
    [app: :crawler,
     version: "0.1.0",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  defp deps do
    [
      {:private_api, in_umbrella: true},
      {:libcluster, github: "bitwalker/libcluster"},
      {:swarm, github: "bitwalker/swarm"},
      {:uuid, "~> 1.1" },
      {:gen_stage, "~> 0.11"},
      {:flow, "~> 0.11"}
    ]
  end

  def application do
    [
      mod: {InstaCrawler.Crawler.Application, []},
      applications: [:libcluster, :swarm, :gen_stage]
    ]
  end

end
