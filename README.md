[![Build and Test](https://github.com/s3cur3/okay_weather/actions/workflows/elixir-build-and-test.yml/badge.svg)](https://github.com/s3cur3/okay_weather/actions/workflows/elixir-build-and-test.yml) [![Elixir Type Linting](https://github.com/s3cur3/okay_weather/actions/workflows/elixir-dialyzer.yml/badge.svg?branch=main)](https://github.com/s3cur3/okay_weather/actions/workflows/elixir-dialyzer.yml) [![Elixir Quality Checks](https://github.com/s3cur3/okay_weather/actions/workflows/elixir-quality-checks.yml/badge.svg)](https://github.com/s3cur3/okay_weather/actions/workflows/elixir-quality-checks.yml) [![codecov](https://codecov.io/gh/s3cur3/okay_weather/branch/main/graph/badge.svg?token=98RJZ7WK8R)](https://codecov.io/gh/s3cur3/okay_weather) [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

# okay_weather 🌦

**The okayest realtime-ish weather library you'll ever see.**

`OkayWeather` is an Elixir package for looking up the current weather in a particular location.

It will work by fetching METAR weather data from NOAA, parsing it, and providing a way to query it based on latitude and longitude or nearest airport.

Why it this just okay? A few reasons:

- The METAR data is *theoretically* updated hourly. In practice, the time between updates can stretch to 90 minutes or even longer, and the NOAA servers are not particularly reliable. We'll cache the most recent data we've seen, but especially for the first run on a fresh server, you're liable to get no data at all.
- The METAR data is coarse. If the location you're interested in is near a major airport, you're in luck. If not, what the METAR provides might be way off. (In the future, we could potentially do a linear interpolation of many weather stations in this case.)

Now, on the other hand, the thing that makes this library okay in a *positive* sense: it's free! Weather data can get expensive, especially at scale. NOAA's data is free, and if you can cache the results, you can get good enough data without breaking the bank.

**Warning**: okay_weather is pre-alpha right now. Please assume everything is broken.
