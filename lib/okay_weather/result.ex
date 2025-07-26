defmodule OkayWeather.Result do
  @moduledoc false

  @type t() :: {:ok, any()} | :error | {:error, any()}

  @doc """
  Unwraps a result, returning the value if it's an `:ok` or the fallback if it's an `:error`.

  ## Examples

      iex> OkayWeather.Result.unwrap({:ok, 1}, "fallback")
      1

      iex> OkayWeather.Result.unwrap({:error, "error"}, 2)
      2

      iex> OkayWeather.Result.unwrap(:error, "fallback")
      "fallback"
  """
  @spec unwrap(t(), any()) :: any()
  def unwrap(result, fallback)
  def unwrap({:ok, value}, _fallback), do: value
  def unwrap(:error, fallback), do: fallback
  def unwrap({:error, _error}, fallback), do: fallback
end
