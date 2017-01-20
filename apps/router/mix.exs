defmodule Router.Mixfile do
  use Mix.Project

  def project do
    [app: :router,
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
      {:crawler, in_umbrella: true},
      {:plug, "~> 1.0"},
      {:cowboy, "~> 1.0.0"},
      {:gen_stage, "~> 0.11.0"}
    ]
  end

  def application do
    [
      mod: {InstaCrawler.Router.Application, []},
      applications: [:cowboy, :plug, :gen_stage]
    ]
  end
end
