import Config

if config_env() == :dev do
  # setup for ecto_dev_logger (https://github.com/fuelen/ecto_dev_logger)
  config :scoped, Scoped.Repo, log: false

  config :scoped, Scoped.Repo,
    username: System.get_env("POSTGRES_USER") || "postgres",
    password: System.get_env("POSTGRES_PASSWORD") || "postgres",
    database: System.get_env("POSTGRES_DB") || "vecufy_dev",
    hostname: System.get_env("POSTGRES_HOST") || "localhost",
    show_sensitive_data_on_connection_error: true,
    stacktrace: true,
    pool_size: 10
end

if config_env() == :test do
  # The MIX_TEST_PARTITION environment variable can be used
  # to provide built-in test partitioning in CI environment.
  # Run `mix help test` for more information.
  config :scoped, Scoped.Repo,
    adapter: Ecto.Adapters.Postgres,
    database: "vecufy_test#{System.get_env("MIX_TEST_PARTITION")}",
    username: System.get_env("POSTGRES_USER") || "postgres",
    password: System.get_env("POSTGRES_PASSWORD") || "postgres",
    hostname: System.get_env("POSTGRES_HOST") || "localhost",
    pool: Ecto.Adapters.SQL.Sandbox
end
