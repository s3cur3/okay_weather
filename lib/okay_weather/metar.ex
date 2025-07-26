defmodule OkayWeather.Metar do
  @enforce_keys [:airport_code]
  defstruct [
    :airport_code,
    :lon_lat,
    :issued,
    :wind_direction_deg,
    :wind_speed_kts,
    :wind_gust_kts,
    :visibility_m,
    :weather_conditions,
    :cloud_layers,
    :temperature_deg_c,
    :dewpoint_deg_c,
    :altimeter,
    :remarks
  ]

  @type t :: %__MODULE__{
          airport_code: String.t(),
          lon_lat: {number(), number()},
          issued: DateTime.t() | nil,
          wind_direction_deg: integer() | nil,
          wind_speed_kts: integer() | nil,
          wind_gust_kts: integer() | nil,
          visibility_m: integer() | nil,
          weather_conditions: [String.t()],
          cloud_layers: [map()],
          temperature_deg_c: integer() | nil,
          dewpoint_deg_c: integer() | nil,
          altimeter: float() | nil,
          remarks: [String.t()]
        }

  @typedoc "A METAR collection maps airport identifier to the latest METAR data"
  @type collection :: %{String.t() => t()}

  @doc """
  Finds the nearest METAR to the given longitude and latitude using the Haversine formula.

  If no METAR is found (because the collection was empty), returns nil.
  """
  @spec nearest(collection() | [t()], {number(), number()}) :: t() | nil
  def nearest(parsed_metars, desired_lon_lat) when is_map(parsed_metars) do
    parsed_metars
    |> Map.values()
    |> nearest(desired_lon_lat)
  end

  def nearest(parsed_metars, desired_lon_lat) when is_list(parsed_metars) do
    parsed_metars
    |> Enum.reject(&is_nil(&1.lon_lat))
    |> Enum.sort_by(fn %__MODULE__{lon_lat: lon_lat} ->
      Haversine.distance(lon_lat, desired_lon_lat)
    end)
    |> List.first()
  end

  @doc """
  Finds the nearest METAR to the given longitude and latitude that satisfies the given predicate.

  If no METAR is found (because the collection was empty or no METAR satisfies the predicate),
  returns nil.
  """
  @spec nearest_where(collection() | [t()], {number(), number()}, (t() -> boolean())) :: t() | nil
  def nearest_where(parsed_metars, desired_lon_lat, predicate) when is_function(predicate, 1) do
    parsed_metars
    |> Map.values()
    |> Enum.filter(predicate)
    |> nearest(desired_lon_lat)
  end

  @type opts :: [issued: DateTime.t()]

  @doc """
  Parses a METAR report into a map of airport codes to weather data.
  """
  @spec parse(String.t(), opts()) :: {:ok, collection()} | {:error, any}
  def parse(metar_text, opts \\ []) do
    issued_date = opts[:issued]

    parsed =
      metar_text
      |> String.split(~r/[\n\r]/)
      |> Enum.map(fn s ->
        s
        |> String.trim()
        |> String.split()
        |> parse_tokenized_line(issued_date)
      end)
      |> Enum.filter(fn
        {nil, _metar} -> false
        {_code, nil} -> false
        _ -> true
      end)
      |> Map.new()

    if Enum.empty?(parsed) do
      {:error, :no_usable_data}
    else
      {:ok, parsed}
    end
  end

  # If we have fewer than two tokens, we can't possibly get anything out of this line
  defp parse_tokenized_line([], _issued_date), do: {nil, nil}
  defp parse_tokenized_line([_], _issued_date), do: {nil, nil}

  defp parse_tokenized_line([apt_code | other_tokens], issued_date) do
    metar = %__MODULE__{
      airport_code: apt_code,
      lon_lat:
        case OkayWeather.Airports.lon_lat(apt_code) do
          {:ok, lon_lat} -> lon_lat
          {:error, :unknown_airport} -> nil
        end,
      issued: parse_issued_date(other_tokens, issued_date),
      wind_direction_deg: parse_wind_direction_deg(other_tokens),
      wind_speed_kts: parse_wind_speed_kts(other_tokens),
      wind_gust_kts: parse_wind_gust_kts(other_tokens),
      visibility_m: parse_visibility_m(other_tokens),
      weather_conditions: parse_weather_conditions(other_tokens),
      cloud_layers: parse_cloud_layers(other_tokens),
      temperature_deg_c: parse_temperature(other_tokens),
      dewpoint_deg_c: parse_dewpoint(other_tokens),
      altimeter: parse_altimeter(other_tokens),
      remarks: parse_remarks(other_tokens)
    }

    {apt_code, metar}
  end

  defp parse_issued_date(tokens, %DateTime{} = issued_date) do
    with {day, hour, minute} when not is_nil(day) and not is_nil(hour) and not is_nil(minute) <-
           {parse_day(tokens), parse_hour(tokens), parse_minute(tokens)},
         {:ok, date} <- Date.new(issued_date.year, issued_date.month, day),
         {:ok, time} <- Time.new(hour, minute, 0, 0),
         {:ok, datetime} <- DateTime.new(date, time) do
      DateTime.truncate(datetime, :second)
    else
      _ -> nil
    end
  end

  defp parse_issued_date(_tokens, nil), do: nil

  defp parse_day(tokens) do
    case Enum.find(tokens, &String.match?(&1, ~r/^\d{6}Z$/)) do
      nil ->
        nil

      date_time_str ->
        day_str = String.slice(date_time_str, 0, 2)

        case Integer.parse(day_str) do
          {day, _} -> day
          _ -> nil
        end
    end
  end

  defp parse_hour(tokens) do
    case Enum.find(tokens, &String.match?(&1, ~r/^\d{6}Z$/)) do
      nil ->
        nil

      date_time_str ->
        hour_str = String.slice(date_time_str, 2, 2)

        case Integer.parse(hour_str) do
          {hour, _} -> hour
          _ -> nil
        end
    end
  end

  defp parse_minute(tokens) do
    case Enum.find(tokens, &String.match?(&1, ~r/^\d{6}Z$/)) do
      nil ->
        nil

      date_time_str ->
        minute_str = String.slice(date_time_str, 4, 2)

        case Integer.parse(minute_str) do
          {minute, _} -> minute
          _ -> nil
        end
    end
  end

  defp parse_wind_direction_deg(tokens) do
    case Enum.find(tokens, &String.match?(&1, wind_regex())) do
      nil ->
        nil

      wind_str ->
        direction_str = String.slice(wind_str, 0, 3)

        case Integer.parse(direction_str) do
          {direction, _} -> direction
          _ -> nil
        end
    end
  end

  defp parse_wind_speed_kts(tokens) do
    case Enum.find(tokens, &String.match?(&1, wind_regex())) do
      nil ->
        nil

      wind_str ->
        # Extract speed after direction (3 chars) and before optional gust
        speed_part = String.slice(wind_str, 3, String.length(wind_str) - 3)

        case Regex.run(~r/^(\d{2,3})(?:G\d{2,3})?KT$/, speed_part) do
          [_, speed_str] ->
            case Integer.parse(speed_str) do
              {speed, _} -> speed
              _ -> nil
            end

          _ ->
            nil
        end
    end
  end

  defp parse_wind_gust_kts(tokens) do
    case Enum.find(tokens, &String.match?(&1, wind_regex())) do
      nil ->
        nil

      wind_str ->
        case Regex.run(~r/G(\d{2,3})KT$/, wind_str) do
          [_, gust_str] ->
            case Integer.parse(gust_str) do
              {gust, _} -> gust
              _ -> nil
            end

          _ ->
            nil
        end
    end
  end

  @miles_to_meters 16_09.344

  defp parse_visibility_m(tokens) do
    # Find visibility_m token that's not a wind token
    case Enum.find(tokens, fn token ->
           (String.match?(token, ~r/^\d{4}$/) or String.match?(token, ~r/^\d+SM$/)) and
             not String.match?(token, wind_regex())
         end) do
      nil ->
        nil

      vis_str ->
        # Handle statute miles (e.g., "10SM")
        if String.ends_with?(vis_str, "SM") do
          miles_str = String.slice(vis_str, 0, String.length(vis_str) - 2)

          case Integer.parse(miles_str) do
            {miles, _} -> miles * @miles_to_meters
            _ -> nil
          end
        else
          # Handle meters (e.g., "5000")
          case Integer.parse(vis_str) do
            {visibility_m, _} -> visibility_m
            _ -> nil
          end
        end
    end
  end

  defp wind_regex, do: ~r/^\d{3}\d{2,3}(?:G\d{2,3})?KT$/

  defp parse_weather_conditions(tokens) do
    Enum.filter(tokens, fn token ->
      # Filter out common non-weather tokens
      String.match?(token, ~r/^[+-]?[A-Z]{2,}$/) and
        not Enum.member?(["KT", "SM", "RMK", "AUTO", "COR"], token)
    end)
  end

  defp parse_cloud_layers(tokens) do
    tokens
    |> Enum.filter(&String.match?(&1, ~r/^[A-Z]{3}\d{3}$/))
    |> Enum.map(fn cloud_str ->
      coverage = String.slice(cloud_str, 0, 3)
      height_str = String.slice(cloud_str, 3, 3)

      case Integer.parse(height_str) do
        {height, _} -> %{coverage: coverage, height_ft: height * 100}
        _ -> %{coverage: coverage, height_ft: nil}
      end
    end)
  end

  defp parse_temperature(tokens) do
    case Enum.find(tokens, &String.match?(&1, ~r/^M?\d{1,2}\/M?\d{1,2}$/)) do
      nil ->
        nil

      temp_token ->
        temp_part = String.split(temp_token, "/") |> List.first()
        parse_temp(temp_part)
    end
  end

  defp parse_dewpoint(tokens) do
    case Enum.find(tokens, &String.match?(&1, ~r/^M?\d{1,2}\/M?\d{1,2}$/)) do
      nil ->
        nil

      temp_token ->
        dewpoint_part = String.split(temp_token, "/") |> List.last()
        parse_temp(dewpoint_part)
    end
  end

  defp parse_altimeter(tokens) do
    case Enum.find(tokens, &String.match?(&1, ~r/^A\d{4}$/)) do
      nil ->
        nil

      alt_str ->
        pressure_str = String.slice(alt_str, 1, 4)

        case Integer.parse(pressure_str) do
          {pressure, _} -> pressure / 100.0
          _ -> nil
        end
    end
  end

  defp parse_remarks(tokens) do
    case Enum.split_while(tokens, &(&1 != "RMK")) do
      {_before_rmk, ["RMK" | remarks]} -> remarks
      _ -> []
    end
  end

  defp parse_temp("M" <> temp_str), do: -String.to_integer(temp_str)
  defp parse_temp(temp_str), do: String.to_integer(temp_str)
end
