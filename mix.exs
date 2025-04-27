defmodule ExCSS.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_css,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nimble_parsec, "~> 0.2"},
      {:jason, "~> 1.1", only: :test, runtime: false}
    ]
  end
end
