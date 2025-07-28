defmodule OkayWeather.Number do
  @moduledoc false

  @spec parse_int(String.t()) :: integer() | nil
  def parse_int(str) when is_binary(str) do
    case Integer.parse(str) do
      {int, _} -> int
      _ -> nil
    end
  end

  def parse_int(str, mapper) do
    case parse_int(str) do
      nil -> nil
      int -> mapper.(int)
    end
  end
end
