use Mix.Config

config :libcluster,
  topologies: [
    default: [
      strategy: Cluster.Strategy.Epmd,
      config: [hosts: [:"alpha@hellinterface", :"beta@hellinterface"]]
    ]
  ]
