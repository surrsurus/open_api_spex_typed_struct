defmodule OpenApiSpexTypedStruct.MixProject do
  use Mix.Project

  def project do
    [
      app: :open_api_spex_typed_struct,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      name: "Open API Spex Typed Struct",
      source_url: "https://github.com/surrsurus/open_api_spex_typed_struct",
      description: "Automatically generate api specs for your typed structs"
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
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:open_api_spex, "~> 3.16"},
      {:typed_struct, "~> 0.3.0"}
    ]
  end

  defp package() do
    [
      name: "open_api_spex_typed_struct",
      files: ~w(lib .formatter.exs mix.exs README*),
      licenses: ["BSD-2-Clause"],
      links: %{"GitHub" => "https://github.com/surrsurus/open_api_spex_typed_struct"}
    ]
  end
end
