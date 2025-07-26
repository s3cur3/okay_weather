defmodule OkayWeather.Airports.ParserTest do
  use ExUnit.Case, async: true
  alias OkayWeather.Airports
  alias OkayWeather.Airports.Airport
  alias OkayWeather.Airports.Parser

  test "parses the airport CSV" do
    airports = Parser.parse_csv(Airports.csv_file_path())
    assert map_size(airports) > 10_000

    assert airports["KLAX"] == %Airport{
             airport_code: "KLAX",
             latitude: 33.942501,
             longitude: -118.407997
           }

    assert airports["KSEA"] == %Airport{
             airport_code: "KSEA",
             latitude: 47.449162,
             longitude: -122.311134
           }

    assert airports["LFPG"] == %Airport{
             airport_code: "LFPG",
             latitude: 49.012798,
             longitude: 2.55
           }
  end
end
