defmodule OkayWeather.Env do
  @moduledoc false

  def get_env(key, default)

  if Mix.env() == :test do
    def get_env(key, default) do
      ProcessTree.get(key,
        cache: false,
        default: Application.get_env(:okay_weather, key, default)
      )
    end

    def put_env(key, value), do: Process.put(key, value)
  else
    def get_env(key, default), do: Application.get_env(:okay_weather, key, default)
  end
end
