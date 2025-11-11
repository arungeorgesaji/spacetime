defmodule Spacetime.MixProject do
  use Mix.Project

  def project do
    [
      app: :spacetime,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript(),
      description: "A version control system where code obeys the laws of physics",
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Spacetime.Application, []}
    ]
  end

  defp deps do
    [
      {:optimus, ">= 0.0.0"},
      {:progress_bar, ">= 0.0.0"},
      {:jason, ">= 0.0.0"}
    ]
  end

  defp escript do
    [main_module: Spacetime.CLI.Main]
  end

  defp package do
    [
      name: "spacetime_scm",
      files: ~w(lib .formatter.exs mix.exs README.md),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/arungeorgesaji/spacetime"}
    ]
  end
end
