use Mix.Config

config :libcluster,
  topologies: [
    default: [
      strategy: Cluster.Strategy.Gossip,
      config: [
        port: 45892,
        if_addr: {0,0,0,0},
        multicast_addr: {230,1,1,251},
        multicast_ttl: 1]]]
