defmodule InstaCrawler.API.Private.Mixfile do
  use Mix.Project

  def project do
    [app: :private_api,
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
      {:httpoison, "~> 0.10.0"},
      {:poison, "~> 3.0"},
      {:exprintf, "~> 0.2.0"}
   ]
  end

  def application do
    [
      applications: app_list(),
    ]
  end

  defp app_list do
    [:httpoison, :exprintf]
  end

end
