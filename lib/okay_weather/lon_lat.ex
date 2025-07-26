defmodule OkayWeather.LonLat do
  @moduledoc """
  Utilities for working with longitude-latitude pairs.
  """

  @type t :: {number(), number()}

  @type input ::
          {number(), number()}
          | %{lon: number(), lat: number()}
          | [{:lon, number()}, {:lat, number()}]

  @doc """
  Parses an input longitude-latitude pair.

  ## Examples

      iex> OkayWeather.LonLat.new!({2.54, 49.0127})
      {2.54, 49.0127}

      iex> OkayWeather.LonLat.new!(%{lon: 2.54, lat: 49.0127})
      {2.54, 49.0127}

      iex> OkayWeather.LonLat.new!([{:lon, 2.54}, {:lat, 49.0127}])
      {2.54, 49.0127}
  """
  @spec new!(input()) :: t()
  # TODO: validate range of lon/lat values
  def new!({lon, lat}) when is_number(lon) and is_number(lat), do: {lon, lat}
  def new!(%{lon: lon, lat: lat}), do: {lon, lat}

  def new!(keyword) when is_list(keyword) do
    keyword = Keyword.validate!(keyword, [:lon, :lat])
    lon = Keyword.fetch!(keyword, :lon)
    lat = Keyword.fetch!(keyword, :lat)
    {lon, lat}
  end

  def new!(input) do
    raise ArgumentError, "Invalid lon/lat input: #{inspect(input)}"
  end
end
