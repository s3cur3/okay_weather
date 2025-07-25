defmodule OkayWeather.MetarTest do
  use ExUnit.Case, async: true
  alias OkayWeather.Metar

  # Tests modeled after MIT-licensed Ruby package `metar-parser`:
  # https://github.com/joeyates/metar-parser/blob/main/spec/parser_spec.rb
  @sample_metar """
  AAAA 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M04/M02 A2910 RMK AO2 P0000
  BBBB 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M01/01 A2910 RMK AO2 P0000

  CCCC 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 20/24 A2910 RMK AO2 P0000
  """

  @simple_metar "LFPG 161430Z 24015G25KT 5000 1100w"

  describe "parsing" do
    test "extracts airport code" do
      assert {:ok, metars} = Metar.parse(@sample_metar)

      assert %{
               "AAAA" => %Metar{airport_code: "AAAA", lon_lat: nil},
               "BBBB" => %Metar{airport_code: "BBBB", lon_lat: nil},
               "CCCC" => %Metar{airport_code: "CCCC", lon_lat: nil}
             } = metars
    end

    test "extracts temperature and dewpoint" do
      assert {:ok, metars} = Metar.parse(@sample_metar)
      assert map_size(metars) == 3

      assert metars["AAAA"].temperature_deg_c == -4
      assert metars["AAAA"].dewpoint_deg_c == -2

      assert metars["BBBB"].temperature_deg_c == -1
      assert metars["BBBB"].dewpoint_deg_c == 1

      assert metars["CCCC"].temperature_deg_c == 20
      assert metars["CCCC"].dewpoint_deg_c == 24
    end

    test "parses basic METAR with station" do
      assert {:ok, metars} = Metar.parse(@simple_metar)
      assert map_size(metars) == 1

      metar = metars["LFPG"]
      assert metar.airport_code == "LFPG"
      assert metar.lon_lat == {2.55, 49.012798}
    end

    test "parses with date" do
      issued_date = ~U[2022-01-16 00:00:00Z]
      assert {:ok, metars} = Metar.parse(@simple_metar, issued: issued_date)

      metar = metars["LFPG"]
      assert metar.issued == ~U[2022-01-16 14:30:00Z]
    end

    test "parses wind information" do
      assert {:ok, metars} = Metar.parse(@simple_metar)
      metar = metars["LFPG"]

      assert metar.wind_direction_deg == 240
      assert metar.wind_speed_kts == 15
      assert metar.wind_gust_kts == 25
    end

    test "parses visibility_m" do
      assert {:ok, metars} = Metar.parse(@simple_metar)
      metar = metars["LFPG"]

      assert metar.visibility_m == 5000
    end

    test "parses cloud layers" do
      assert {:ok, metars} = Metar.parse(@sample_metar)
      metar = metars["AAAA"]

      assert length(metar.cloud_layers) == 2
      [bkn, ovc] = metar.cloud_layers

      assert bkn.coverage == "BKN"
      assert bkn.height_ft == 1600

      assert ovc.coverage == "OVC"
      assert ovc.height_ft == 3000
    end

    test "parses weather conditions" do
      assert {:ok, metars} = Metar.parse(@sample_metar)
      metar = metars["AAAA"]

      assert "-SN" in metar.weather_conditions
    end

    test "parses altimeter" do
      assert {:ok, metars} = Metar.parse(@sample_metar)
      metar = metars["AAAA"]

      assert metar.altimeter == 29.10
    end

    test "parses remarks" do
      assert {:ok, metars} = Metar.parse(@sample_metar)
      metar = metars["AAAA"]

      assert "AO2" in metar.remarks
      assert "P0000" in metar.remarks
    end

    test "handles METAR without temperature/dewpoint" do
      metar_text = "KLAX 161430Z 24015KT 10SM CLR A3000"
      assert {:ok, metars} = Metar.parse(metar_text)

      metar = metars["KLAX"]
      assert metar.lon_lat == {-118.407997, 33.942501}
      assert metar.temperature_deg_c == nil
      assert metar.dewpoint_deg_c == nil
      assert metar.wind_direction_deg == 240
      assert metar.wind_speed_kts == 15
      assert metar.wind_gust_kts == nil
      ten_miles_in_meters = 16_093.44
      assert metar.visibility_m == ten_miles_in_meters
      assert metar.altimeter == 30.00
    end

    test "handles METAR with gust but no temperature" do
      metar_text = "KLAX 161430Z 24015G25KT 10SM CLR A3000"
      assert {:ok, metars} = Metar.parse(metar_text)

      metar = metars["KLAX"]
      assert metar.wind_gust_kts == 25
    end

    test "handles empty or invalid METAR" do
      assert {:error, :no_usable_data} = Metar.parse("")
      assert {:error, :no_usable_data} = Metar.parse("   ")
      assert {:error, :no_usable_data} = Metar.parse("INVALID")
    end

    test "handles METAR with missing issued date" do
      assert {:ok, metars} = Metar.parse(@simple_metar, %{})
      metar = metars["LFPG"]
      assert metar.issued == nil
    end

    test "handles METAR with invalid date components" do
      # Invalid day 32
      invalid_metar = "KLAX 321430Z 24015KT 10SM CLR A3000"
      issued_date = ~U[2022-01-16 00:00:00Z]
      assert {:ok, metars} = Metar.parse(invalid_metar, %{issued: issued_date})

      metar = metars["KLAX"]
      # Should be nil due to invalid date
      assert metar.issued == nil
    end
  end

  describe "nearest" do
    test "finds the nearest METAR" do
      metars = %{
        "LFPG" => %Metar{airport_code: "LFPG", lon_lat: {2.55, 49.012798}},
        "KLAX" => %Metar{airport_code: "KLAX", lon_lat: {-118.407997, 33.942501}},
        "KORD" => %Metar{airport_code: "KORD", lon_lat: {-87.904822, 41.978603}}
      }

      assert Metar.nearest(metars, {2.55, 49.012798}) == metars["LFPG"]
      assert Metar.nearest(metars, {-118.407997, 33.942501}) == metars["KLAX"]
      assert Metar.nearest(metars, {-87.904822, 41.978603}) == metars["KORD"]

      assert Metar.nearest(metars, {0, 0}) == metars["LFPG"]
      assert Metar.nearest(metars, {-110, 30}) == metars["KLAX"]
    end
  end
end
