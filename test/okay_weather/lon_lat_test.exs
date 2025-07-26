defmodule OkayWeather.LonLatTest do
  use ExUnit.Case, async: true
  doctest OkayWeather.LonLat
  alias OkayWeather.LonLat

  test "new!/1 raises with invalid input" do
    assert_raise ArgumentError, "Invalid lon/lat input: %{lat: 1.23}", fn ->
      LonLat.new!(%{lat: 1.23})
    end
  end
end
