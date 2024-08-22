defmodule Essig.MixProject do
  use Mix.Project

  def project do
    [
      app: :essig,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
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
      extra_applications: [:logger, :observer, :wx],
      mod: {Essig.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:liveness, "~> 1.0.0"},
      {:dryhard, "~> 0.1"},
      {:ecto_cursor_based_stream, "~> 1.0.2"},
      {:uniq, "~> 0.6"},
      {:ets_select, "~> 0.1.2"},
      {:data_tracer, "~> 0.1"},
      {:json_serde, github: "maxohq/json_serde"},
      {:maxo_test_iex, "~> 0.1.7", only: [:test]},
      {:mneme, "~> 0.8", only: [:test]}
    ]
  end
end
