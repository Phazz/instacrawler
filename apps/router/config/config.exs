use Mix.Config

config :router,
  port: System.get_env("COWBOY_PORT") || 4567
