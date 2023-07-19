defmodule OkayWeather.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    HTTPoison.start()

    children = [
      {Registry, keys: :unique, name: OkayWeather.AutoUpdatingUrlCache},
      cache_spec(:metar, &OkayWeather.UrlGen.metar/1)
    ]

    opts = [strategy: :one_for_one, name: OkayWeather.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp cache_spec(name, url_generator) when is_atom(name) and is_function(url_generator) do
    %{
      id: name,
      start: {OkayWeather.AutoUpdatingUrlCache, :start_link, [name, url_generator]}
    }
  end
end
