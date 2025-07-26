defmodule OkayWeather do
  @moduledoc """
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
      latitude = 56.78
      longitude = 12.34
      %OkayWeather.Metar{} = metar = OkayWeather.nearest_metar(%{lon: longitude, lat: latitude})
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
  """
  alias OkayWeather.AutoUpdatingCache
  alias OkayWeather.LonLat
  alias OkayWeather.Metar
  alias OkayWeather.Result

  @doc """
  Finds the nearest METAR to the given longitude and latitude from the cache.

  Will never return nil, since even if the network fetch fails on startup, we fall back
  to a local (disk) cache that ships with the package.

  Note that opts are for testing purposes only.

  ## Example

      iex> match?(
      ...>   %OkayWeather.Metar{airport_code: "LFPG", lon_lat: {2.55, 49.012798}},
      ...>   OkayWeather.nearest_metar(%{lon: 2.54, lat: 49.0127})
      ...> )
      true
  """
  @spec nearest_metar(LonLat.input(), keyword) :: OkayWeather.Metar.t()
  def nearest_metar(lon_lat, opts \\ []) do
    ll = LonLat.new!(lon_lat)

    Metar.nearest(metars(opts), ll)
  end

  @doc """
  Finds the nearest METAR to the given longitude and latitude that satisfies the given predicate.

  Note that opts are for testing purposes only.

  ## Examples

      iex> match?(
      ...>   %OkayWeather.Metar{airport_code: "LFPG"},
      ...>   OkayWeather.nearest_metar_where(
      ...>     [lon: 0, lat: 0],
      ...>     fn %OkayWeather.Metar{airport_code: code} -> code == "LFPG" end
      ...>   )
      ...> )
      true
  """
  @spec nearest_metar_where(LonLat.input(), (Metar.t() -> boolean()), keyword) ::
          OkayWeather.Metar.t() | nil
  def nearest_metar_where(lon_lat, predicate, opts \\ []) do
    ll = LonLat.new!(lon_lat)
    Metar.nearest_where(metars(opts), ll, predicate)
  end

  @doc "Return all METARs we know about"
  @spec metars(keyword) :: Metar.collection()
  def metars(opts \\ []) do
    opts = Keyword.validate!(opts, [:name])

    (opts[:name] || :metar)
    |> AutoUpdatingCache.get()
    # This will never be unpopulated, since we fill the cache on startup, falling back
    # to a local cache that ships with the package if the network fetch fails.
    |> Result.unwrap(%{})
  end
end
