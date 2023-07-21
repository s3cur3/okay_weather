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

  test "extracts airport code" do
    assert {:ok, metars} = Metar.parse(@sample_metar)
    assert map_size(metars) == 3

    for airport_code <- ["AAAA", "BBBB", "CCCC"] do
      assert metars[airport_code].airport_code == airport_code
    end
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
end
