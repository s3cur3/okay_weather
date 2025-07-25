defmodule OkayWeather do
  @moduledoc """
  A library for looking up the current weather in a particular location.

  It will work by fetching METAR weather data from NOAA, parsing it, and providing a way to query it based on latitude and longitude or nearest airport.

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
  2. Add `OkayWeather` to your `applications` list in `mix.exs`:
    ```elixir
    def application do
    [
      extra_applications: [:logger, :okay_weather],
    ]
    end
    ```
  3. Add `OkayWeather` to your supervision tree in your `application.ex`:
    ```elixir
    def start(_type, _args) do
      children = [
        OkayWeather.child_spec(),
      ]
      ...
    end
    ```
  4. Run `mix deps.get`
  """
  alias OkayWeather.AutoUpdatingCache.State

  @spec child_spec([{:update_interval_ms, pos_integer()}]) :: Supervisor.child_spec()
  def child_spec(opts \\ [update_interval_ms: :timer.minutes(5)]) do
    opts = Keyword.validate!(opts, update_interval_ms: :timer.minutes(5))
    update_timeout = opts[:update_interval_ms]
    cache_spec(:metar, &OkayWeather.UrlGen.metar/1, &OkayWeather.Metar.parse/1, update_timeout)
  end

  @spec cache_spec(atom, State.url_generator(), State.transform(), pos_integer()) ::
          Supervisor.child_spec()
  defp cache_spec(name, url_generator, transform, update_timeout)
       when is_integer(update_timeout) do
    args = [name, url_generator, transform, update_timeout]
    %{id: name, start: {OkayWeather.AutoUpdatingCache, :start_link, args}}
  end
end
