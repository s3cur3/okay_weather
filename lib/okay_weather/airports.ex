defmodule OkayWeather.Airports do
  alias OkayWeather.Airports.Airport

  # Airports taken from public domain source https://ourairports.com/data/
  @csv_file_path Path.join([__DIR__, "..", "..", "priv", "airports.csv"])
  @external_resource @csv_file_path
  @airports OkayWeather.Airports.Parser.parse_csv(@csv_file_path)

  @airports_by_lon_lat @airports
                       |> Map.values()
                       |> Enum.group_by(&{floor(&1.longitude), floor(&1.latitude)})

  @spec lon_lat(String.t()) :: {:ok, {float(), float()}} | {:error, :unknown_airport}
  def lon_lat(airport_code) do
    case airports()[airport_code] do
      nil -> {:error, :unknown_airport}
      %Airport{latitude: lat, longitude: lon} -> {:ok, {lon, lat}}
    end
  end

  def nearest_to_lon_lat(lon, lat) do
  end

  @spec in_lon_lat_bucket(float(), float()) :: [Airport.t()]
  def in_lon_lat_bucket(lon, lat) do
    lon_bucket = floor(lon)
    lat_bucket = floor(lat)
    @airports_by_lon_lat[{lon_bucket, lat_bucket}]
  end

  defp airports, do: @airports
end
