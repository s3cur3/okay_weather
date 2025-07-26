[![Build and Test](https://github.com/s3cur3/okay_weather/actions/workflows/elixir-build-and-test.yml/badge.svg)](https://github.com/s3cur3/okay_weather/actions/workflows/elixir-build-and-test.yml) [![Elixir Type Linting](https://github.com/s3cur3/okay_weather/actions/workflows/elixir-dialyzer.yml/badge.svg?branch=main)](https://github.com/s3cur3/okay_weather/actions/workflows/elixir-dialyzer.yml) [![Elixir Quality Checks](https://github.com/s3cur3/okay_weather/actions/workflows/elixir-quality-checks.yml/badge.svg)](https://github.com/s3cur3/okay_weather/actions/workflows/elixir-quality-checks.yml) [![Coverage Status](https://coveralls.io/repos/github/s3cur3/okay_weather/badge.svg)](https://coveralls.io/github/s3cur3/okay_weather) [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/s3cur3/okay_weather/blob/main/LICENSE)

# okay_weather 🌦

**The okayest live-ish weather library you'll ever see.**

`OkayWeather` is an Elixir package for looking up the current weather in a particular location.

It works by fetching [METAR weather data](https://en.wikipedia.org/wiki/METAR) from NOAA, parsing it, and providing a way to query it based on latitude and longitude or nearest airport.

Why it this just okay? A few reasons:

- The METAR data is *theoretically* updated hourly. In practice, the time between updates can stretch to 90 minutes or even longer, and the NOAA servers are not particularly reliable. We'll cache the most recent data we've seen, but especially for the first run on a fresh server, you're liable to get no data at all.
- The METAR data is coarse. If the location you're interested in is near a major airport, you're in luck. If not, what the METAR provides might be way off. (In the future, we could potentially do a linear interpolation of many weather stations in this case.)

Now, on the other hand, the thing that makes this library okay in a *positive* sense: it's free! Weather data can get expensive, especially at scale. NOAA's data is free, and if you can cache the results, you can get good enough data without breaking the bank.

**Warning**: okay_weather is pre-alpha right now. Please assume everything is broken.

## Installation

1. Add the package to your `mix.exs`:
```elixir
  defp deps do
  [
    {:okay_weather, github: "s3cur3/okay_weather"},
  ]
  end
```
2. Run `mix deps.get`
3. Optional, but strongly recommended: add OkayWeather configuration
    (see below) to your `config/test.exs` and `config/dev.exs` files.
4. Use it:
    ```elixir
    %OkayWeather.Metar{} = metar = OkayWeather.nearest_metar({12.34, 56.78}) do
    ```

## Configuration

There is only one application-level config value, `:fetch_before_startup?`.
This controls whether OkayWeather should attempt to fetch the latest 
weather data *prior* to your application's startup.

```elixir
config :okay_weather, fetch_before_startup?: true
```

This defaults to true for the sake of correctness; when true, any call
to `OkayWeather.*` will always be working from the latest available data.
However, you almost certainly want this to be false in test environments
(e.g., in your `config/test.exs`) and probably in dev as well 
(`config/dev.exs`) so that you don't add a few seconds for a synchronous
network request to the startup time of your application and test suite.

When false, initial calls to OkayWeather functions will use METAR data from
either the last successful fetch the application cached (if your 
`System.tmp_dir!/0` remains in place from a prior successful launch of the
application) or from an extremely old METAR that ships with the package.
