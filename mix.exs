defmodule Supernamed.MixProject do
  use Mix.Project

  def project do
    [
      app: :supernamed,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :observer, :wx],
      mod: {Supernamed.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:liveness, "~> 1.0.0"},
      {:maxo_test_iex, "~> 0.1.7", only: [:test]}
    ]
  end
end
