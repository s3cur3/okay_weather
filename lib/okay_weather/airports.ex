defmodule OkayWeather.Airports do
  @moduledoc false
  alias OkayWeather.Airports.Airport

  # Airports taken from public domain source https://ourairports.com/data/
  @csv_file_path Path.join([__DIR__, "..", "..", "priv", "airports.csv"])
  @external_resource @csv_file_path
  @airports OkayWeather.Airports.Parser.parse_csv(@csv_file_path)

  def csv_file_path, do: @csv_file_path

  @spec lon_lat(String.t()) :: {:ok, {number(), number()}} | {:error, :unknown_airport}
  def lon_lat(airport_code) do
    case @airports[airport_code] do
      nil -> {:error, :unknown_airport}
      %Airport{latitude: lat, longitude: lon} -> {:ok, {lon, lat}}
    end
  end
end
