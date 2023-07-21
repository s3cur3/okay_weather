defmodule OkayWeather.Airports.Airport do
  use TypedStruct

  typedstruct enforce: true do
    field :airport_code, String.t()
    field :latitude, number()
    field :longitude, number()
  end
end
