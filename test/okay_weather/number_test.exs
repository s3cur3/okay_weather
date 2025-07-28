defmodule OkayWeather.NumberTest do
  use ExUnit.Case, async: true
  doctest OkayWeather.Number
  alias OkayWeather.Number

  test "parse_int/{1,2} returns nil for invalid input" do
    refute Number.parse_int("not a number")
    refute Number.parse_int("doesn't start with a number 123")
    refute Number.parse_int("doesn't start with a number 123", &(&1 * 2))
  end

  test "parse_int/1 takes the int a string starts with" do
    assert Number.parse_int("123.45") == 123
    assert Number.parse_int("123.45", &(&1 * 100)) == 12_300
  end
end
