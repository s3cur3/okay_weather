defmodule OkayWeather.Airports.Airport do
  @enforce_keys [:airport_code, :latitude, :longitude]
  defstruct [:airport_code, :latitude, :longitude]

  @type t :: %__MODULE__{
          airport_code: String.t(),
          latitude: number(),
          longitude: number()
        }
end
