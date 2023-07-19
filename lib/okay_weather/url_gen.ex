defmodule OkayWeather.UrlGen do
  @moduledoc """
  Generates for NOAA weather URLs
  """

  def metar(%DateTime{} = utc_date \\ DateTime.utc_now()) do
    # 1 hour in the past because the current hour at NOAA is always 0 bytes
    prev_hour = rem(23 + utc_date.hour, 24)
    formatted_hour = leading_zero_hour(prev_hour)
    "https://tgftp.nws.noaa.gov/data/observations/metar/cycles/#{formatted_hour}Z.TXT"
  end

  defp leading_zero_hour(hour) when hour < 10, do: "0#{hour}"
  defp leading_zero_hour(hour), do: to_string(hour)
end
