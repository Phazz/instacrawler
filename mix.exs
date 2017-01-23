defmodule Instacrawler.Mixfile do
  use Mix.Project

  def project do
    [apps_path: "apps",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  defp deps do
    [
      {:credo, "~> 0.5", only: [:dev, :test]},
      {:distillery, "~> 1.0"},
      {:dotenv, "~> 2.0.0"},
      {:confex, "~> 1.4.1"}
    ]
  end

  def application do
    [
      applications: app_list(Mix.env)
    ]
  end

  defp app_list(:dev), do: [:dotenv | app_list()]
  defp app_list(_), do: app_list()

  defp app_list do
    [:logger, :confex]
  end
end
