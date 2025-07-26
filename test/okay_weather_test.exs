defmodule OkayWeatherTest do
  use ExUnit.Case, async: true
  doctest OkayWeather, tags: [:integration]
  alias OkayWeather.Metar

  setup do
    bypass = Bypass.open()
    %{bypass: bypass, bypass_domain: "http://localhost:#{bypass.port}"}
  end

  test "nearest_metar", %{bypass: bypass, bypass_domain: bypass_domain} do
    lfpg = %Metar{airport_code: "LFPG", lon_lat: {2.55, 49.012798}}

    OkayWeather.Env.put_env(:fetch_before_startup?, true)
    OkayWeather.Env.put_env(:update_timeout, :infinity)

    Bypass.expect_once(bypass, "GET", "/", fn conn ->
      Plug.Conn.resp(conn, 200, "")
    end)

    test_server = :metar_test

    {:ok, _pid} =
      Supervisor.start_link(
        [
          OkayWeather.Application.cache_spec(
            name: test_server,
            url_generator: fn _datetime -> bypass_domain end,
            transform: fn _raw_metar -> {:ok, %{"LFPG" => lfpg}} end,
            update_timeout: :infinity
          )
        ],
        strategy: :one_for_one,
        name: OkayWeather.TestSupervisor
      )

    assert OkayWeather.nearest_metar({0, 0}, name: test_server) == lfpg
  end
end
