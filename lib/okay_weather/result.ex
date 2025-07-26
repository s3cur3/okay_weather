defmodule OkayWeather.Result do
  @moduledoc false

  def unwrap(result, fallback \\ nil)
  def unwrap({:ok, value}, _fallback), do: value
  def unwrap(:error, fallback), do: fallback
  def unwrap({:error, _error}, fallback), do: fallback
end
