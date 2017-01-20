use Mix.Config

config :storage,
  hostname: System.get_env("MONGODB_HOSTNAME") || "localhost",
  port: System.get_env("MONGODB_PORT") || 27017,
  username: System.get_env("MONGODB_USER"),
  password: System.get_env("MONGODB_PASSWORD"),
  database: System.get_env("MONGODB_DATABASE") || "instacrawler"
