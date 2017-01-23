use Mix.Config

config :storage,
  hostname: {:system, "MONGODB_HOSTNAME", "localhost"},
  port: {:system, :integer, "MONGODB_PORT", 27017},
  username: {:system, "MONGODB_USER"},
  password: {:system, "MONGODB_PASSWORD"},
  database: {:system, "MONGODB_DATABASE", "instacrawler"}
