defmodule Scoped.MixProject do
  use Mix.Project

  def project do
    [
      app: :scoped,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_paths: ["lib"],
      test_pattern: "*_test.exs"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :observer, :wx],
      mod: {Scoped.Application, []}
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
      {:maxo_test_iex, "~> 0.1.7", only: [:test]}
    ]
  end
end
