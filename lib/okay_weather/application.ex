defmodule OkayWeather.Application do
  @moduledoc false

  use Application
  alias OkayWeather.AutoUpdatingCache

  @impl Application
  def start(_type, _opts) do
    children = [
      {Task.Supervisor, name: OkayWeather.FetchSupervisor},
      {Registry, keys: :unique, name: AutoUpdatingCache},
      cache_spec()
    ]

    opts = [strategy: :one_for_one, name: OkayWeather.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @typep start_opts :: [{:update_interval_ms, pos_integer()} | {:name, atom()}]

  @doc false
  @spec cache_spec(start_opts()) :: Supervisor.child_spec()
  def cache_spec(opts \\ []) do
    name = opts[:name] || :metar

    args = [
      name,
      %AutoUpdatingCache.Spec{
        url_generator: opts[:url_generator] || (&OkayWeather.UrlGen.metar/1),
        transform: opts[:transform] || (&OkayWeather.Metar.parse/1),
        update_timeout: opts[:update_interval_ms] || :timer.minutes(5)
      }
    ]

    %{id: name, start: {AutoUpdatingCache, :start_link, args}}
  end
end
