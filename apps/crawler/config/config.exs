use Mix.Config

import_config "libcluster.exs"

config :crawler,
  gateway_timeout: 30_000

config :logger,
  level: :debug
