defmodule OkayWeather.AirportsTest do
  use ExUnit.Case, async: true
  alias OkayWeather.Airports

  test "parses the airport CSV" do
    assert Airports.lon_lat("KSEA") == {:ok, {-122.311134, 47.449162}}
    assert Airports.lon_lat("00A") == {:ok, {-74.93360137939450, 40.07080078125}}
    assert Airports.lon_lat("ZZZZ") == {:ok, {130.270556, 30.784722}}
  end
end
