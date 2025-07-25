defmodule OkayWeather.Metar do
  @enforce_keys [:airport_code]
  defstruct [:airport_code, :temperature_deg_c, :dewpoint_deg_c]

  @type t :: %__MODULE__{
          airport_code: String.t(),
          temperature_deg_c: integer() | nil,
          dewpoint_deg_c: integer() | nil
        }

  @doc """
  Parses a METAR report into a map of airport codes to weather data.
  """
  @spec parse(String.t()) :: {:ok, %{String.t() => t()}} | {:error, any}
  def parse(metar_text) do
    parsed =
      metar_text
      |> String.split(~r/[\n\r]/)
      |> Enum.map(&String.trim/1)
      |> Enum.map(&String.split/1)
      |> Map.new(&parse_tokenized_line/1)
      |> Map.delete(nil)

    if Enum.empty?(parsed) do
      {:error, :no_usable_data}
    else
      {:ok, parsed}
    end
  end

  # If we have fewer than two tokens, we can't possibly get anything out of this line
  defp parse_tokenized_line([]), do: {nil, nil}
  defp parse_tokenized_line([_]), do: {nil, nil}

  defp parse_tokenized_line([apt_code | other_tokens]) do
    {temp_c, dewpoint_c} = parse_temp_and_dewpoint(other_tokens)

    metar = %__MODULE__{
      airport_code: apt_code,
      temperature_deg_c: temp_c,
      dewpoint_deg_c: dewpoint_c
    }

    {apt_code, metar}
  end

  defp parse_temp_and_dewpoint(tokens) do
    # Standard temp format is 04/20, indicating 4 deg C temp and 20 deg C dewpoint.
    # An M in front of either number indicates negative (minus).
    # There are other tokens in the row that may include a slash, though, like 3/4SM,
    # indicating prevailing visibility of 0.75 statute miles.
    case Enum.find(tokens, &String.match?(&1, ~r/^M?\d{1,2}\/M?\d{1,2}$/)) do
      nil ->
        {nil, nil}

      temp_token ->
        temp_token
        |> String.split("/")
        |> Enum.map(&parse_temp/1)
        |> List.to_tuple()
    end
  end

  defp parse_temp("M" <> temp_str), do: -String.to_integer(temp_str)
  defp parse_temp(temp_str), do: String.to_integer(temp_str)
end
