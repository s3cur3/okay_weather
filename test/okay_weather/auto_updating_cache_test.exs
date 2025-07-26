defmodule OkayWeather.AutoUpdatingCacheTest do
  use ExUnit.Case, async: true
  alias OkayWeather.AutoUpdatingCache

  setup do
    bypass = Bypass.open()
    %{bypass: bypass, bypass_domain: "http://localhost:#{bypass.port}"}
  end

  test "works with simple URLs", %{bypass: bypass, bypass_domain: bypass_domain} do
    body = "Hello, world"

    Bypass.expect_once(bypass, "GET", "/", fn conn ->
      Plug.Conn.resp(conn, 200, body)
    end)

    {:ok, server} =
      AutoUpdatingCache.start_link(
        :url_test,
        %AutoUpdatingCache.Spec{
          url_generator: fn _ -> bypass_domain end,
          transform: fn body -> {:ok, String.upcase(body)} end
        }
      )

    assert AutoUpdatingCache.get(server) == {:ok, String.upcase(body)}
  end

  @tag :timing
  test "updates on a schedule", %{bypass: bypass, bypass_domain: bypass_domain} do
    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(conn, 200, "#{DateTime.utc_now()}")
    end)

    update_interval_ms = 100

    {:ok, server} =
      AutoUpdatingCache.start_link(
        :url_test,
        %AutoUpdatingCache.Spec{
          url_generator: fn _ -> bypass_domain end,
          transform: fn body -> {:ok, body} end,
          update_timeout: update_interval_ms
        }
      )

    {:ok, initial_result} = AutoUpdatingCache.get(server)
    assert is_binary(initial_result)

    Process.sleep(update_interval_ms * 4)

    assert {:ok, updated_result} = AutoUpdatingCache.get(server)
    assert is_binary(updated_result)
    assert initial_result != updated_result
  end
end
