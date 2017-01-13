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
     deps: deps]
  end

  defp deps do
    [
      {:libcluster, "~> 2.0"},
      {:swarm, "~> 3.0"},
      {:cowboy, "~> 1.0.0"},
      {:plug, "~> 1.0"},
      { :uuid, "~> 1.1" },
      {:private_api, in_umbrella: true}
    ]
  end

  def application do
    [
      mod: {InstaCrawler.Crawler.Application, []},
      applications: [:libcluster, :private_api, :swarm, :plug, :cowboy]
    ]
  end

end
