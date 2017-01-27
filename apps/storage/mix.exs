defmodule Storage.Mixfile do
  use Mix.Project

  def project do
    [app: :storage,
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
      {:mongodb, github: "ericmj/mongodb"},
      {:gen_stage, "~> 0.11"}
    ]
  end

  def application do
    [
      mod: {InstaCrawler.Storage.Application, []},
      applications: [:gen_stage, :mongodb]
    ]
  end

end
