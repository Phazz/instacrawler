use Mix.Config

import_config "libcluster.exs"

config :crawler,
  cowboy_port: System.get_env("COWBOY_PORT") || 4567,
  client_timeout: 30000

config :logger,
  level: :info
