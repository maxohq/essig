defmodule Essig.MixProject do
  use Mix.Project

  def project do
    [
      app: :essig,
      version: "0.1.0",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      test_paths: ["test", "lib"],
      test_pattern: "*_test.exs"
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: extra_apps(Mix.env()),
      mod: {Essig.Application, []}
    ]
  end

  defp extra_apps(:dev), do: [:logger, :observer, :wx]
  defp extra_apps(_), do: [:logger]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      ## DB
      {:dryhard, "~> 0.1"},
      {:ecto_cursor_based_stream, "~> 1.0.2"},

      ## ETS
      {:ets_select, "~> 0.1.2"},

      ## PUB-SUB
      {:phoenix_pubsub, "~> 2.1"},

      ## UTIL
      {:json_serde, github: "maxohq/json_serde"},
      {:liveness, "~> 1.0.0"},
      {:uniq, "~> 0.6"},

      ## DEBUG
      {:data_tracer, "~> 0.1"},

      ## DEV
      {:maxo_test_iex, "~> 0.1.7", only: [:test]},
      {:mneme, "~> 0.8", only: [:test]}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "essig.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: [
        "ecto.create --quiet",
        "essig.migrate --quiet",
        "test"
      ]
    ]
  end
end
