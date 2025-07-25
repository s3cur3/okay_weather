defmodule OkayWeather.AutoUpdatingCacheTest do
  use ExUnit.Case, async: true
  alias OkayWeather.AssertionHelpers
  alias OkayWeather.AutoUpdatingCache

  setup do
    bypass = Bypass.open()
    bypass_domain = "http://localhost:#{bypass.port}"

    %{bypass: bypass, bypass_domain: bypass_domain}
  end

  test "works with simple URLs", %{bypass: bypass, bypass_domain: bypass_domain} do
    body = "Hello, world"

    Bypass.expect_once(bypass, "GET", "/", fn conn ->
      Plug.Conn.resp(conn, 200, body)
    end)

    {:ok, server} =
      AutoUpdatingCache.start_link(
        :url_test,
        fn _ -> bypass_domain end,
        fn body -> {:ok, String.upcase(body)} end
      )

    await_content(server)
    assert AutoUpdatingCache.get(server) == String.upcase(body)
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
        fn _ -> bypass_domain end,
        fn body -> {:ok, body} end,
        update_interval_ms
      )

    await_content(server)
    initial_result = AutoUpdatingCache.get(server)
    assert is_binary(initial_result)

    Process.sleep(update_interval_ms * 4)

    updated_result = AutoUpdatingCache.get(server)
    assert is_binary(updated_result)
    assert initial_result != updated_result
  end

  defp await_content(pid) do
    ExUnit.CaptureLog.capture_log(fn ->
      AssertionHelpers.await(fn -> AutoUpdatingCache.get(pid) != :error end)
    end)
  end
end
