NimbleCSV.define(OkayWeather.Airports.NimbleParser, separator: ",", escape: "\"")

defmodule OkayWeather.Airports.Parser do
  @moduledoc false
  alias OkayWeather.Airports.Airport

  @spec parse_csv(String.t()) :: %{String.t() => Airport.t()}
  def parse_csv(file_path) do
    file_path
    |> File.stream!()
    |> OkayWeather.Airports.NimbleParser.parse_stream()
    |> Stream.map(fn
      [_, "ident", _, _, "latitude_deg", "longitude_deg" | _] ->
        {nil, nil}

      [_, ident, _, _, lat, lon | _] ->
        %Airport{
          airport_code: ident,
          latitude: parse_number(lat),
          longitude: parse_number(lon)
        }
    end)
    |> Map.new(&{&1.airport_code, &1})
    |> Map.delete(nil)
  end

  defp parse_number(val) do
    String.to_float(val)
  rescue
    _ -> String.to_integer(val)
  end
end
