defmodule OkayWeather.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Finch, name: OkayWeather.Finch}
    ]

    opts = [strategy: :one_for_one, name: Cbt.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
