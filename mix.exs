defmodule Webring.MixProject do
  use Mix.Project

  def project do
    [
      app: :webring,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: { Webring, [] },
      extra_applications: [:cowboy, :ranch, :logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~> 2.8"}
    ]
  end
end
