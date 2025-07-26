defmodule OkayWeather.AssertionHelpers do
  import ExUnit.Assertions

  @doc """
  Asserts that a predicate becomes true within the given timeout.
  """
  @spec await((-> boolean), timeout) :: boolean
  def await(predicate, timeout \\ :timer.seconds(10))

  def await(predicate, timeout) when timeout <= 0 do
    assert predicate.()
  end

  def await(predicate, timeout) do
    start_time = DateTime.utc_now()

    try do
      assert predicate.()
    rescue
      _ ->
        elapsed_ms = DateTime.diff(DateTime.utc_now(), start_time, :millisecond)
        await(predicate, timeout - elapsed_ms)
    end
  end
end
