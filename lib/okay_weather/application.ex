defmodule OkayWeather.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    HTTPoison.start()

    children = [
      {Task.Supervisor, name: OkayWeather.FetchSupervisor},
      {Registry, keys: :unique, name: OkayWeather.AutoUpdatingCache},
      cache_spec(:metar, &OkayWeather.UrlGen.metar/1, &OkayWeather.Metar.parse/1)
    ]

    opts = [strategy: :one_for_one, name: OkayWeather.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp cache_spec(name, url_generator, transform)
       when is_atom(name) and is_function(url_generator, 1) and is_function(transform, 1) do
    %{
      id: name,
      start: {OkayWeather.AutoUpdatingCache, :start_link, [name, url_generator, transform]}
    }
  end
end
