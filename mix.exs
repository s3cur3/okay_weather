defmodule OkayWeather.MixProject do
  use Mix.Project

  @source_url "https://github.com/s3cur3/okay_weather"
  @version "0.1.0"

  def project do
    [
      app: :okay_weather,
      version: @version,
      elixir: "~> 1.15",
      consolidate_protocols: Mix.env() != :test,
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      description:
        "A package for looking up the current weather (from NOAA-supplied METAR files) in a particular location",
      docs: docs(),
      test_coverage: [tool: ExCoveralls],
      package: package(),
      preferred_cli_env: [
        check: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        dialyzer: :dev,
        "test.all": :test
      ],
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore.exs",
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        flags: [:error_handling, :unknown],
        # Error out when an ignore rule is no longer useful so we can remove it
        list_unused_filters: true
      ]
    ]
  end

  def application do
    [mod: {OkayWeather.Application, []}, extra_applications: [:logger, :runtime_tools]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      maintainers: ["Tyler Young"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(mix.exs priv/airports.csv priv/metar.txt lib README.md LICENSE CHANGELOG.md)
    ]
  end

  defp docs() do
    [
      main: "readme",
      name: "OkayWeather",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/okay_weather",
      source_url: @source_url,
      extras: ["README.md"]
    ]
  end

  defp deps do
    [
      {:bypass, "~> 2.1", only: [:test]},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.17", only: [:dev, :test], runtime: false},
      {:ex_waiter, "1.3.1", only: [:test]},
      {:haversine, "~> 0.1"},
      {:nimble_csv, "~> 1.1"},
      {:plug, "~> 1.15", only: [:test]},
      {:process_tree, "~> 0.2", only: [:test]},
      {:req, "~> 0.4"}
    ]
  end

  defp aliases do
    [
      check: [
        "clean",
        "deps.unlock --check-unused",
        "compile --warnings-as-errors",
        "format --check-formatted",
        "test.all --warnings-as-errors",
        "credo",
        "check.circular",
        "check.dialyzer"
      ],
      "check.circular": "cmd MIX_ENV=dev mix xref graph --label compile-connected --fail-above 1",
      "check.dialyzer": "cmd MIX_ENV=dev mix dialyzer",
      setup: ["deps.get"],
      "test.all": ["test --include timing --include integration"]
    ]
  end
end
