defmodule OkayWeather.AutoUpdatingCache.Spec do
  @moduledoc """
  Specs for the auto updating cache.
  """

  @type url_generator :: (DateTime.t() -> String.t())
  @type transform :: (String.t() -> {:ok, any} | {:error, any})

  @type t :: %__MODULE__{
          url_generator: url_generator(),
          transform: transform(),
          update_timeout: timeout() | nil
        }

  @enforce_keys [:url_generator, :transform]
  defstruct [:url_generator, :transform, :update_timeout]
end
