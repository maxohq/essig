import Config

config :essig,
  ecto_repos: [Essig.Repo],
  generators: [timestamp_type: :utc_datetime]

config :essig, Essig.PubSub, adapter: Phoenix.PubSub.PG2

if config_env() == :dev do
  # setup for ecto_dev_logger (https://github.com/fuelen/ecto_dev_logger)
  config :essig, Essig.Repo, log: false

  config :essig, Essig.Repo,
    username: System.get_env("POSTGRES_USER") || "postgres",
    password: System.get_env("POSTGRES_PASSWORD") || "postgres",
    database: System.get_env("POSTGRES_DB") || "essig_dev",
    hostname: System.get_env("POSTGRES_HOST") || "localhost",
    show_sensitive_data_on_connection_error: true,
    stacktrace: true,
    pool_size: 10
end

if config_env() == :test do
  # The MIX_TEST_PARTITION environment variable can be used
  # to provide built-in test partitioning in CI environment.
  # Run `mix help test` for more information.
  config :essig, Essig.Repo,
    adapter: Ecto.Adapters.Postgres,
    database: "essig_test#{System.get_env("MIX_TEST_PARTITION")}",
    username: System.get_env("POSTGRES_USER") || "postgres",
    password: System.get_env("POSTGRES_PASSWORD") || "postgres",
    hostname: System.get_env("POSTGRES_HOST") || "localhost",
    pool: Ecto.Adapters.SQL.Sandbox
end
