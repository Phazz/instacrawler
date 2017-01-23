use Mix.Config

config :router,
  port: {:system, :integer, "COWBOY_PORT", 4567}
