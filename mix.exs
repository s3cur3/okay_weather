defmodule OkayWeather.MixProject do
  use Mix.Project

  def project do
    [
      app: :okay_weather,
      version: "0.1.0",
      elixir: "~> 1.14",
      consolidate_protocols: Mix.env() != :test,
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        check: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        dialyzer: :dev
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

  defp deps do
    [
      {:bypass, "~> 2.1", only: [:test]},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18.5", only: [:dev, :test], runtime: false},
      {:ex_waiter, "1.3.1", only: [:test]},
      {:httpoison, "~> 2.1"},
      {:nimble_csv, "~> 1.1"},
      {:plug, "~> 1.15.0", only: [:test]},
      {:typed_struct, "~> 0.3.0", runtime: false},
      {:union_typespec,
       git: "https://github.com/felt/union_typespec.git", tag: "v0.0.2", runtime: false}
    ]
  end

  defp aliases do
    [
      check: [
        "clean",
        "deps.unlock --check-unused",
        "compile --warnings-as-errors",
        "format --check-formatted",
        "test --warnings-as-errors",
        "credo",
        "check.circular",
        "check.dialyzer"
      ],
      "check.circular": "cmd MIX_ENV=dev mix xref graph --label compile-connected --fail-above 1",
      "check.dialyzer": "cmd MIX_ENV=dev mix dialyzer",
      setup: ["deps.get"]
    ]
  end
end
