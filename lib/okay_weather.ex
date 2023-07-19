defmodule OkayWeather do
  @moduledoc """
  An Elixir package for looking up the current weather in a particular location.

  It will work by fetching METAR weather data from NOAA, parsing it, and providing a way to query it based on latitude and longitude or nearest airport.

  Why it this just okay? A few reasons:

  - The METAR data is *theoretically* updated hourly. In practice, the time between updates can stretch to 90 minutes or even longer, and the NOAA servers are not particularly reliable. We'll cache the most recent data we've seen, but especially for the first run on a fresh server, you're liable to get no data at all.
  - The METAR data is coarse. If the location you're interested in is near a major airport, you're in luck. If not, what the METAR provides might be way off. (In the future, we could potentially do a linear interpolation of many weather stations in this case.)

  Now, on the other hand, the thing that makes this library okay in a *positive* sense: it's free! Weather data can get expensive, especially at scale. NOAA's data is free, and if you can cache the results, you can get good enough data without breaking the bank.

  **Warning**: okay_weather is pre-alpha right now. Please assume everything is broken.
  """
end
