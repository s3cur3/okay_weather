defmodule OkayWeather.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    HTTPoison.start()

    children = [
      {Task.Supervisor, name: OkayWeather.FetchSupervisor},
      {Registry, keys: :unique, name: OkayWeather.AutoUpdatingCache}
    ]

    opts = [strategy: :one_for_one, name: OkayWeather.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
