defmodule OkayWeather.AirportsTest do
  use ExUnit.Case, async: true
  alias OkayWeather.Airports

  test "parses the airport CSV" do
    assert Airports.lon_lat("KSEA") == {:ok, {-122.311134, 47.449162}}
    assert Airports.lon_lat("00A") == {:ok, {-74.93360137939450, 40.07080078125}}
    assert Airports.lon_lat("ZZZZ") == {:ok, {130.270556, 30.784722}}
  end

  test "buckets airports by lon/lat" do
    airports_in_bucket = Airports.in_lon_lat_bucket(-122.3, 47.4)
    assert length(airports_in_bucket) > 100
    assert length(airports_in_bucket) < 1_000

    codes_in_bucket = Enum.map(airports_in_bucket, & &1.airport_code)
    assert "KSEA" in codes_in_bucket
    assert "KGRF" in codes_in_bucket
    assert "KBFI" in codes_in_bucket
  end
end
