defmodule OkayWeather.Summary do
  @moduledoc """
  A summary of the weather at a particular location.
  """
  @enforce_keys [:temperature_deg_c, :temperature_feel, :wind_level, :cloud_cover]
  defstruct [:temperature_deg_c, :temperature_feel, :wind_level, :cloud_cover]

  @type t :: %__MODULE__{
          temperature_deg_c: integer(),
          temperature_feel: :cold | :cool | :nice | :warm | :hot,
          wind_level: nil | :light | :moderate | :high | :gale | :storm,
          cloud_cover: nil | :clear | :few | :scattered | :broken | :overcast
        }
end
