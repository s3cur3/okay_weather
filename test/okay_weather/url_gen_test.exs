defmodule OkayWeather.UrlGenTest do
  use ExUnit.Case, async: true
  alias OkayWeather.UrlGen

  test "generates METAR URLs" do
    test_date = DateTime.from_unix!(1_550_019_493)

    assert UrlGen.metar(test_date) ==
             "https://tgftp.nws.noaa.gov/data/observations/metar/cycles/23Z.TXT"
  end
end
