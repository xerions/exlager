defmodule Exlager.Mixfile do
  use Mix.Project

  def project do
    [
      app: :exlager,
      version: "0.14.0",
      elixir: "~> 1.2",
      deps: deps()
    ]
  end

  def application do
    [
      applications: [
        :compiler,
        :syntax_tools,
        :lager
      ]
    ]
  end

  defp deps do
    [
      {:lager, "~> 3.6.3"}
    ]
  end
end

